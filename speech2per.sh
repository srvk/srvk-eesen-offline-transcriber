#!/bin/bash

# (based on speech2text.sh)
#
# Given an input audio, and a plain text file containing words,
# produce a phonetic transcription and compute phone error rate
# of the audio as it relates to the text file as "gold standard"

BASEDIR=$(dirname $0)

echo "$0 $@"  # Print the command line for logging

. path.sh

txt=""
trs=""
ctm=""
sbv=""
srt=""
clean=false
nthreads=""
nnet2_online=false

. $BASEDIR/utils/parse_options.sh || exit 1;

if [ $# -ne 2 ]; then
  echo "Usage: speech2per <stmfile> <audiofile>"
  exit 1;
fi

stmfilename=$(basename "$1")
stmbasename="${stmfilename%.*}"

hypfilename=$(basename "$2")
hypbasename="${hypfilename%.*}"

cp -u $2 $BASEDIR/src-audio

nnet2_online_arg="DO_NNET2_ONLINE=no"

(cd $BASEDIR; make build/output/${hypbasename%.*}.{txt,trs,ctm,sbv,srt,labels} || exit 1; if $clean ; then make .${hypbasename%.*}.clean; fi)

cd $BASEDIR

# if not exist, create gold phonetic STM
local/words2phon.sh $1 | paste -s -d ' ' > build/output/${stmbasename}.phon.stm

# put phonetic transcription in output folder (not part of Makefile)
python local/flatphonemes.py build/trans/${hypbasename}/eesen/decode/phones.1.txt > build/trans/${hypbasename}/eesen/decode/${hypbasename}.hyp

# score phonetic transcription against phonetic STM
compute-wer --text ark:build/output/${stmbasename}.phon.stm ark:build/trans/${hypbasename}/eesen/decode/${hypbasename}.hyp build/output/${hypbasename}.dtl > build/output/${hypbasename}.phon.sys
# fix 'WER' to read 'PER" since these are phones
sed -i 's/WER/PER/g' build/output/${hypbasename}.phon.sys

echo ${hypbasename} `grep PER build/output/${hypbasename}.phon.sys` >> speech2per.log

rm $BASEDIR/src-audio/$hypfilename

echo "Finished transcribing, result is in files $BASEDIR/build/output/${hypbasename%.*}.{txt,trs,ctm,sbv,srt,labels,sys,dtl}"

if [ ! -z $txt ]; then
 cp $BASEDIR/build/output/${basename%.*}.txt $txt
 echo $txt
fi

if [ ! -z $trs ]; then
 cp $BASEDIR/build/output/${basename%.*}.trs $trs
fi
                                                                   
if [ ! -z $ctm ]; then
 cp $BASEDIR/build/output/${basename%.*}.ctm $ctm
fi
                                                                   
if [ ! -z $sbv ]; then
 cp $BASEDIR/build/output/${basename%.*}.sbv $sbv
fi  

if [ ! -z $srt ]; then
 cp $BASEDIR/build/output/${basename%.*}.srt $srt
fi

if [ ! -z $labels ]; then
 cp $BASEDIR/build/output/${basename%.*}.labels $labels
fi

