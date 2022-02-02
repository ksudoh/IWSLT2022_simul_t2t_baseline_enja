#!/bin/bash

###
### Train a subword unigram model using SentencePiece 
###

basedir=`dirname $0`
scriptdir=${basedir}/scripts
FAIRSEQ_ROOT=${basedir}/fairseq-mma-il/fairseq
. ${scriptdir}/00-env.sh

parse_options "$@"
shift $?
if test ${verbose} -gt 0 ; then set -x ; fi

max_epoch=70
dropout=0.3
label_smoothing=0.1
max_tokens=7168
update_freq=4
model_output_dir=${nmt_model_dir}/mma-il

if test -e ${model_output_dir}/.done ; then
    notice "Skipped the model training on ${model_output_dir}."
else
    tmpdir=`tempfile`
    /bin/rm ${tmpdir}
    make_dir `dirname ${model_output_dir}`

    if env PYTHONPATH=${FAIRSEQ_ROOT} ${python3} ${FAIRSEQ_ROOT}/train.py \
        ${preprocessed_data_dir} \
		--save-dir ${tmpdir} \
        --source-lang ${SRC} \
        --target-lang ${TRG} \
        --simul-type infinite_lookback \
        --max-epoch ${max_epoch} \
		--arch transformer_monotonic_vaswani_wmt_en_de_big \
    	--optimizer adam  \
    	--adam-betas '(0.9, 0.98)'  \
    	--lr-scheduler inverse_sqrt  \
    	--warmup-init-lr 1e-07  \
    	--warmup-updates 4000  \
    	--lr 0.0005  \
    	--stop-min-lr 1e-09  \
    	--clip-norm 10.0  \
    	--dropout ${dropout}  \
    	--weight-decay 0.0  \
        --mass-preservation \
    	--criterion latency_augmented_label_smoothed_cross_entropy  \
        --latency-weight-avg 0.1 \
    	--label-smoothing ${label_smoothing}  \
    	--max-tokens ${max_tokens} \
		--update-freq ${update_freq} ; then
        /bin/mv ${tmpdir} ${train_out}
    else
        error_and_die "Failed to train the model on ${model_output_dir}."
    fi
fi
