#!/bin/bash

###
### Text data preparation script for IWSLT 2022 text-to-text baselines
###

basedir=`dirname $0`
scriptdir=${basedir}/scripts
FAIRSEQ_ROOT=${basedir}/fairseq-waitk/fairseq
. ${scriptdir}/00-env.sh

parse_options "$@"
shift $?
if test ${verbose} -gt 0 ; then set -x ; fi

### MuST-C
for dataset in train dev tst-COMMON ; do
    extract_bilingual ${MUSTC_ROOT}/${SRC}-${TRG}/data/${dataset}/txt/${dataset} ${raw_corpus_dir}/mustc-${dataset} ${mustc_corpustype} ${mustc_column_src} ${mustc_column_trg}
done

### Other corpora
for corpus in ${trainset_add[@]} ; do
    extract_bilingual ${wmt_data_dir}/$(eval echo \${${corpus}_name}) ${raw_corpus_dir}/${corpus} $(eval echo \${${corpus}_corpustype}) $(eval echo \${${corpus}_column_src}) $(eval echo \${${corpus}_column_trg})
done

preprocess_and_merge_bilingual train ${raw_corpus_dir} ${split_corpus_dir} ${trainset[@]} ${trainset_add[@]}
preprocess_and_merge_bilingual valid ${raw_corpus_dir} ${split_corpus_dir} ${validset[@]}
preprocess_and_merge_bilingual devtest ${raw_corpus_dir} ${split_corpus_dir} ${devtestset[@]}

train_spm ${split_corpus_dir}/train ${sentencepiece_dir}/${SRC}${TRG}.spm

tokenize_spm train ${split_corpus_dir} ${tokenized_corpus_dir} ${sentencepiece_dir}/${SRC}${TRG}.spm ${training_min_len} ${training_max_len}
tokenize_spm valid ${split_corpus_dir} ${tokenized_corpus_dir} ${sentencepiece_dir}/${SRC}${TRG}.spm 1 0
tokenize_spm devtest ${split_corpus_dir} ${tokenized_corpus_dir} ${sentencepiece_dir}/${SRC}${TRG}.spm 1 0

fairseq_preprocess ${tokenized_corpus_dir}/train ${tokenized_corpus_dir}/valid ${sentencepiece_dir}/${SRC}${TRG}.spm ${preprocessed_data_dir}

exit 0
