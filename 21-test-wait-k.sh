#!/bin/bash

###
### Train a wait-k model
###

basedir=`dirname $0`
scriptdir=${basedir}/scripts
FAIRSEQ_ROOT=${basedir}/fairseq-waitk/fairseq
SIMULEVAL_ROOT=${basedir}/SimulEval
. ${scriptdir}/00-env.sh

parse_options "$@"
shift $?
if test ${verbose} -gt 0 ; then set -x ; fi

if test -z "${K}" ; then
    K=20
fi
model_dir=${model_basedir}/wait-${K}
devtest_dir=${devtest_basedir}/wait-${K}

decoder_options=""
if test ${TRG} = "ja" ; then
    decoder_options="${decoder_options} --sacrebleu-tokenizer ja-mecab"
    decoder_options="${decoder_options} --eval-latency-unit char --no-space"
    decoder_options="${decoder_options} --src-splitter-type sentencepiecemodel"
    decoder_options="${decoder_options} --src-splitter-path ${sentencepiece_dir}/${SRC}${TRG}.spm.model"
fi

if test ! -s ${model_dir}/checkpoint_best.pt ; then
    error_and_die "No model checkpoints are found in ${model_dir}."
elif test ! -e ${model_dir}/.done ; then
    warn "The model training has not completed. The best intermediate checkpoint will be used."
fi

for dataset in ${devtestset[@]} ; do
    env PYTHONPATH="${FAIRSEQ_ROOT}:${SIMULEVAL_ROOT}" \
        ${python3} ${SIMULEVAL_ROOT}/bin/simuleval \
            --agent ${FAIRSEQ_ROOT}/examples/simultaneous_translation/eval/agents/simul_t2t_enja.py \
            --source ${mustc_data_dir}/${dataset:6}/txt/${dataset:6}.${SRC} \
            --target ${mustc_data_dir}/${dataset:6}/txt/${dataset:6}.${TRG} \
            --data-bin ${preprocessed_data_dir} \
            --model-path ${model_dir}/checkpoint_best.pt \
            --output ${devtest_dir}/${dataset} \
            --scores ${decoder_options} \
            --gpu
done
