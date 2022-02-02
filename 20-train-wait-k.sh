#!/bin/bash

###
### Train a wait-k model
###

basedir=`dirname $0`
scriptdir=${basedir}/scripts
FAIRSEQ_ROOT=${basedir}/fairseq-waitk/fairseq
. ${scriptdir}/00-env.sh

parse_options "$@"
shift $?
if test ${verbose} -gt 0 ; then set -x ; fi

if test -z "${K}" ; then
    K=20
fi
max_epoch=70
dropout=0.3
label_smoothing=0.1
max_tokens=7168
update_freq=4
model_output_dir=${model_basedir}/wait-${K}

if test -e ${model_output_dir}/.done ; then
    notice "Skipped the model training on ${model_output_dir}."
else
    if test -s ${model_output_dir}/checkpoint_last.pt ; then
        notice "Intermediate models are found in ${model_output_dir}. Restarting the training."
        tmpdir=${model_output_dir}
    else
        tmpdir=`tempfile`
        /bin/rm ${tmpdir}
        make_dir `dirname ${model_output_dir}`
    fi

    if env PYTHONPATH=${FAIRSEQ_ROOT} ${python3} ${FAIRSEQ_ROOT}/train.py \
        ${preprocessed_data_dir} \
		--save-dir ${tmpdir} \
        --source-lang ${SRC} \
        --target-lang ${TRG} \
        --simul-type waitk \
        --waitk-lagging ${K} \
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
    	--criterion label_smoothed_cross_entropy  \
    	--label-smoothing ${label_smoothing}  \
    	--max-tokens ${max_tokens} \
		--update-freq ${update_freq} ; then
        if test ${tmpdir} != ${model_output_dir} ; then
            /bin/mv ${tmpdir} ${model_output_dir}
        fi
        touch ${model_output_dir}/.done
    else
        if test ${tmpdir} != ${model_output_dir} && test -s ${model_output_dir}/checkpoint_last.pt ; then
            /bin/mv ${tmpdir} ${model_output_dir}
        fi
        error_and_die "Failed to train the model on ${model_output_dir}. Intermediate checkpoints may be found there."
    fi
fi
