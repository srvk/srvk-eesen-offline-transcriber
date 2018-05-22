#!/bin/bash

# (based on speech2text.sh)
#
# Given an input audio, and a plain text file containing words,
# do STT transcription and compute word error rate
# of the transcript as it relates to the text file as "gold standard"

BASEDIR=$(dirname $0)

echo "$0 $@"  # Print the command line for logging

. path.homebank.sh

# Tedlium + Eesen
#segments=show.seg
#models=tedlium.eesen
# Swbd8K + Eesen
#segments=show.s.seg
#models=swbd.8k
# Aspire + Kald
segments=show.seg
models=aspire.kaldi

txt=""
trs=""
ctm=""
sbv=""
srt=""
clean=false
nthreads=""
nnet2_online=false

#. $BASEDIR/utils/parse_options.sh

if [ $# -lt 1 ]; then
    echo "Usage: speech2wer.sh <audiofile>.wav [GLM file]"
    echo "       computes WER against <audiofile>.stm and optionally"
    echo "       applies global mapping of substitution words in GLM file"
    echo "       sclite score outputs appear as"
    echo "       build/output/[<audiofile>.raw <audiofile>.sys <audiofile>.prf <audiofile>.dtl]"
  exit 1;
fi

ApplyGLM=false
if [ "$2" != "" ] && [ -f $2 ]; then
    ApplyGLM=true
else
    ApplyGLM=false
fi

filename=$(basename "$1")
basename="${filename%.*}"
dirname=$(dirname "$1")
stmfilename=${dirname}/${basename}.stm

cp $1 $BASEDIR/src-audio

# VERY IMPORTANT: clean up first
rm -rf build/output/${basename}.*
rm -rf build/trans/${basename}
rm -rf build/audio/*/${basename}
rm -rf build/diarization/${basename}

(cd $BASEDIR; make SEGMENTS=$segments MODELS=$models build/output/${basename%.*}.txt || exit 1;)

cd $BASEDIR

# remove periods, newlines, then downcase
sed -e 's/\.//g' build/output/${basename}.txt | tr '\n' ' ' | tr '[:upper:]' '[:lower:]' >> build/trans/${basename}/eesen/decode/${basename}.hyp
# add final newline
echo >> build/trans/${basename}/eesen/decode/${basename}.hyp


# Filter (substitute) words from GLobalMapping (.glm) file
if [ "$ApplyGLM" == true ]; then
    cat build/trans/${basename}/eesen/decode/${basename}.hyp | \
	csrfilt.sh -i txt -t hyp -dh $2 > \
	build/output/${basename}.filt.hyp
else
    cat build/trans/${basename}/eesen/decode/${basename}.hyp > build/output/${basename}.filt.hyp
fi

# score with sclite
sclite -i wsj -r ${stmfilename}  -h build/output/${basename}.filt.hyp -F -o sum rsum dtl prf -n ${basename}

rm $BASEDIR/src-audio/$filename

echo "Finished transcribing, result is in files $BASEDIR/build/output/${basename%.*}"

