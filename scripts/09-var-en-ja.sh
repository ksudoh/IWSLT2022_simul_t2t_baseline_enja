#!/bin/bash

###
### Variables for IWSLT 2022 English-to-Japanese Simultaneous text-to-text baselines
###

trainset_add=(newscommentary wikititles wikimatrix jesc kftt)

newscommentary_corpustype="TSV"
newscommentary_name=news-commentary-v16.${SRC}-${TRG}.tsv
newscommentary_column_src=1
newscommentary_column_trg=2

wikimatrix_corpustype="wikimatrix"
wikimatrix_name=WikiMatrix.v1.${SRC}-${TRG}.langid.tsv
wikimatrix_column_src=2
wikimatrix_column_trg=3

wikititles_corpustype="TSV"
wikititles_name=wikititles-v3.${TRG}-${SRC}.tsv
wikititles_column_src=2
wikititles_column_trg=1

jesc_corpustype="TSV"
jesc_name=raw/raw
jesc_column_src=1
jesc_column_trg=2

kftt_corpustype="TXT"
kftt_name=kftt-data-1.0/data/orig/kyoto-train
kftt_column_src=0
kftt_column_trg=0

jparacrawl_corpustype="TSV"
jparacrawl_name=${SRC}-${TRG}/${SRC}-${TRG}.bicleaner05.txt
jparacrawl_column_src=3
jparacrawl_column_trg=4


extract_wikimatrix () {
    input=$1
    output_prefix=$2
    column_src=$3
    column_trg=$4

    local tmpfile=`tempfile -m 0644`
    if grep "	${SRC}	${TRG}\$" ${input} > ${tmpfile} ; then
        extract_column ${tmpfile} ${column_src} ${output_prefix}.${SRC}
        extract_column ${tmpfile} ${column_trg} ${output_prefix}.${TRG}
    else
        error_and_die "Failed to extract the ${SRC}-${TRG} portion from ${wikimatrix_name}."
    fi
    return 0
}
