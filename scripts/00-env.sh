###
### Environment variables and common subroutines for IWSLT 2022
###   English-to-Japanese Simultaneous text-to-text baselines
###
#set -e
. ${scriptdir}/01-common.sh

##
## Check environment variables
##
check_env SRC TRG WORKDIR MUSTC_ROOT WMT_DATA_ROOT FAIRSEQ_ROOT

##
## Set fairseq root
##
FAIRSEQ_WAITK=

##
## Parameters
##
python3=python3
sentencepiece_vocab_size=32768
sentencepiece_num_threads=8
sentencepiece_character_coverage=0.99995
sentencepiece_pad_id=3
training_min_len=1
training_max_len=200
preprocess_workers=8

##
## Common variables
##
utilsdir=${basedir}/utils
preprocess_text_src=${utilsdir}/preprocess_text_${SRC}.py
preprocess_text_trg=${utilsdir}/preprocess_text_${TRG}.py
spm_train=${FAIRSEQ_ROOT}/scripts/spm_train.py
spm_encode=${FAIRSEQ_ROOT}/scripts/spm_encode.py

langpair=${SRC}-${TRG}
mustc_data_dir=${MUSTC_ROOT}/${langpair}
wmt_data_dir=${WMT_DATA_ROOT}

mustc_corpustype="TXT"
mustc_name=""
mustc_column_src=0
mustc_column_trg=0

trainset=(mustc-train)
validset=(mustc-dev)
devtestset=(mustc-tst-COMMON)

corpusdir=${WORKDIR}/corpus/${langpair}
raw_corpus_dir=${corpusdir}/1_raw
split_corpus_dir=${corpusdir}/2_split
tokenized_corpus_dir=${corpusdir}/3_tokenized
corpusdir=${WORKDIR}/corpus/${langpair}

sentencepiece_dir=${WORKDIR}/sentencepiece/${langpair}
preprocessed_data_dir=${WORKDIR}/preprocessed/${langpair}
nmt_model_dir=${WORKDIR}/model/${langpair}

##
## Check directories and utilities
##
check_dir ${utilsdir} ${MUSTC_ROOT} ${mustc_data_dir} ${WMT_DATA_ROOT} ${wmt_data_dir} ${FAIRSEQ_ROOT}
check_file ${preprocess_text_src} ${preprocess_text_trg}

##
## Import common functions
##
. ${scriptdir}/02-func.sh

##
## Import language-pair-dependent variables and subroutines
##
if test -s ${scriptdir}/09-var-${SRC}-${TRG}.sh ; then
    . ${scriptdir}/09-var-${SRC}-${TRG}.sh
fi
