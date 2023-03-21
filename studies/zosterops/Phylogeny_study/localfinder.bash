#!/bin/bash
CHRS=$1

echo $(date)
echo "Processing ${CHRS} for local individuals"

mkdir -p "${CHRS}/locales/"
head -n 1 ${CHRS}/inds_s*.tsv > $CHRS/locales/localinds.tsv

for id in $(<ctlocales.txt)
do
	grep "^\S\+\s${id}" \
		"${CHRS}/inds_s"*.tsv \
		>> $CHRS/locales/localinds.tsv
done

tail -n +2 "$CHRS/locales/localinds.tsv" |
	cut -f 12 \
	> "$CHRS/locales/indids.txt" 

grep -A 1 -f "$CHRS/locales/indids.txt" \
	"${CHRS}/seqs_s"*.fa \
	> "${CHRS}/locales/indseqs.fa"
