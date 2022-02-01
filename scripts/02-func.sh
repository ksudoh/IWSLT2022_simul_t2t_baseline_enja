###
### Common subroutines for IWSLT 2022
###   English-to-Japanese Simultaneous text-to-text baselines
###

#
# Other common subroutines
#
extract_column () {
    local tsv=$1
    local column=$2
    local output=$3

    if test -s ${output} ; then
        notice "Skipped ${output}."
    else
        local tmpfile=`tempfile -m 0644`
        if cut -f ${column} ${tsv} > ${tmpfile} ; then
            if ! /bin/mv ${tmpfile} ${output} ; then
                error_and_die "Failed to move a temporary file to ${output}."
            fi
        else
            error_and_die "Failed to extract column ${column} from ${tsv}."
        fi
    fi

    return 0
}

extract_bilingual () {
    local input=$1
    local output_prefix=$2
    local type=$3
    local column_src=$4
    local column_trg=$5

    if test -s ${output_prefix}.${SRC} && test -s ${output_prefix}.${TRG} ; then
        notice "Skipped ${output_prefix}."
    else
        make_dir `dirname ${output_prefix}`
        if test ${type} == "TSV" ; then
            check_file ${input}
            extract_column ${input} ${column_src} ${output_prefix}.${SRC}
            extract_column ${input} ${column_trg} ${output_prefix}.${TRG}
        elif test ${type} == "TXT" ; then
            check_file ${input}.${SRC} ${input}.${TRG}
            copy_file ${input}.${SRC} ${output_prefix}.${SRC}
            copy_file ${input}.${TRG} ${output_prefix}.${TRG}
        else
            extract_${type} ${input} ${output_prefix} ${column_src} ${column_trg}
        fi
    fi

    return 0
}

preprocess_and_merge () {
    local script=$1
    local outfile=$2
    shift 2

    if test -s ${outfile} ; then
        warn "Notice: Skipped ${outfile}"
    else
        local tmpfile=`tempfile -m 0644`
        for infile in $* ; do
            python3 ${script} < ${infile}
            if test $? -ne 0 ; then
                error_and_die "Error: failed to preprocess input file ${infile}"
            fi
        done > ${tmpfile}
        if ! /bin/mv ${tmpfile} ${outfile} ; then
            error_and_die "Error: failed to copy ${tmpfile} to ${outfile}"
        fi
    fi
    return 0
}

preprocess_and_merge_bilingual () {
    local dataset=$1
    local input_dir=$2
    local output_dir=$3
    shift 3

    if test -s ${output_dir}/${dataset}.${SRC} && test -s ${output_dir}/${dataset}.${TRG} ; then
        notice "Skipped ${output_dir}."
    else
        make_dir ${output_dir}
        local srcs=()
        local trgs=()
        for corpus in $* ; do
            check_file ${input_dir}/${corpus}.${SRC} ${input_dir}/${corpus}.${TRG}
            srcs+=(${input_dir}/${corpus}.${SRC})
            trgs+=(${input_dir}/${corpus}.${TRG})
        done
        preprocess_and_merge ${preprocess_text_src} ${output_dir}/${dataset}.${SRC} ${srcs[@]}
        preprocess_and_merge ${preprocess_text_trg} ${output_dir}/${dataset}.${TRG} ${trgs[@]}
    fi

    return 0
}

train_spm () {
    local input_prefix=$1
    local model_prefix=$2

    if test -s ${model_prefix}.model ; then
        notice "Skipped ${model_prefix}.model."
    else
        local tmpfile=""
        if test -s ${model_prefix}.train.txt ; then
            tmpfile=${model_prefix}.train.txt
        else
            tmpfile=`tempfile -m 0644`
            cat ${input_prefix}.${SRC} ${input_prefix}.${TRG} > ${tmpfile}
        fi
    
        make_dir ${sentencepiece_dir}
        
        local tmpmodel=`tempfile -m 0644`
        /bin/rm ${tmpmodel}
        local numlines=`cat ${tmpfile} | wc -l`
        if ${python3} ${spm_train} --input=${tmpfile} --model_prefix=${tmpmodel} --vocab_size=${sentencepiece_vocab_size} --num_threads=${sentencepiece_num_threads} --seed_sentencepiece_size=${numlines} --character_coverage=${sentencepiece_character_coverage} --pad_id=${sentencepiece_pad_id} --train_extremely_large_corpus=true ; then
            if test ${tmpfile} != "${model_prefix}.train.txt" ; then
                /bin/mv ${tmpfile} ${model_prefix}.train.txt
            fi
            /bin/mv ${tmpmodel}.vocab ${model_prefix}.vocab
            /bin/mv ${tmpmodel}.model ${model_prefix}.model
        else
            error_and_die "Error: failed to train a subword unigram model ${model_prefix}.model."
        fi
    fi
    
    if test ! -s ${model_prefix}.dict ; then
        tail +5 ${model_prefix}.vocab | sed -e "s,\t.*, 1," > ${model_prefix}.dict
    fi

    return 0
}

tokenize_spm () {
    local dataset=$1
    local input_dir=$2
    local output_dir=$3
    local model_prefix=$4
    local min_len=$5
    local max_len=$6
    local tmpfile_src=`tempfile -m 0644`
    local tmpfile_trg=`tempfile -m 0644`

    if test -s ${output_dir}/${dataset}.${SRC} && test -s ${output_dir}/${dataset}.${TRG} ; then
        notice "Skipped ${output_dir}/${dataset}."
    else
        make_dir ${output_dir}
        local localopt=""
        if test ${max_len} -gt 0 ; then
            localopt="--max-len ${max_len}"
        fi

        if ${python3} ${spm_encode} --model ${model_prefix}.model --inputs ${input_dir}/${dataset}.${SRC} ${input_dir}/${dataset}.${TRG} --outputs ${tmpfile_src} ${tmpfile_trg} --min-len ${min_len} ${localopt} ; then
            /bin/mv ${tmpfile_src} ${output_dir}/${dataset}.${SRC}
            /bin/mv ${tmpfile_trg} ${output_dir}/${dataset}.${TRG}
        else
            die "Error: failed to tokenize ${input_dir}/${dataset}."
        fi
    fi

    return 0
}

fairseq_preprocess () {
    local train_prefix=$1
    local valid_prefix=$2
    local sentencepiece_model_prefix=$3
    local data_dir=$4

    if test -d ${data_dir} ; then
        notice "Skipped ${data_dir}"
    else
        local tmpdir=`tempfile`
        /bin/rm ${tmpdir}
        make_dir `dirname ${data_dir}`
        if env PYTHONPATH=${FAIRSEQ_ROOT} ${python3} ${FAIRSEQ_ROOT}/fairseq_cli/preprocess.py \
            --source-lang ${SRC} --target-lang ${TRG} \
            --trainpref ${train_prefix} --validpref ${valid_prefix} \
            --destdir ${tmpdir} \
            --srcdict ${sentencepiece_model_prefix}.dict --tgtdict ${sentencepiece_model_prefix}.dict \
            --workers ${preprocess_workers} ; then
            /bin/mv ${tmpdir} ${data_dir}
        else
            error_and_die "Failed to preprocess the corpus."
        fi
    fi

    return 0
}
