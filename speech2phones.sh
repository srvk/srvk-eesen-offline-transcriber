#!/bin/bash

BASEDIR=$(dirname $0)

echo "$0 $@"  # Print the command line for logging

txt=""
trs=""
ctm=""
sbv=""
srt=""
clean=false
nthreads=""
nnet2_online=false

. $BASEDIR/utils/parse_options.sh || exit 1;
. $BASEDIR/path.sh

if [ $# -ne 1 ]; then
  echo "Usage: speech2phones.sh <audiofile>"
  exit 1;
fi

mkdir -p $BASEDIR/build/audio/base build/output

DIRNAME=$(dirname $1)

nthreads_arg=""
if [ ! -z $nthreads ]; then
  echo "Using $nthreads threads for decoding"
  nthreads_arg="nthreads=$nthreads"
fi
  
cp -u $1 $BASEDIR/src-audio

filename=$(basename "$1")
basename="${filename%.*}"

(cd $BASEDIR; make $nthreads_arg build/output/${basename%.*}.ctm || exit 1; )

# put phonetic transcription in output folder (not part of Makefile)
cd $BASEDIR
python local/readphonemes.py build/trans/${basename}/eesen/decode/phones.1.txt | sort -n -t '-' -k5 > build/output/${basename}.phones
# needs numeric sorted by timestamp!

rm $BASEDIR/src-audio/$filename

echo "Finished transcribing, result is in files $BASEDIR/build/output/${basename%.*}.phones"
