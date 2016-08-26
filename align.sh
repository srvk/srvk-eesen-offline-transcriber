#!/bin/bash

# Copyright 2016  er1k
# Apache 2.0

# Prepare data for, and run align_ctc_utts.sh script that generates word-level alignments
# in an "Eesen Transccriber-centric" way  output is found in build/trans/<basename>/align/ali

# Required inputs:
#
# * a 'hypothesis' text file for which to compute alignments, extension .txt
#   one utterance per line. If no hypothesis text is found, text
#   is obtained from the STM file below
# * an STM file with utterance/segment timings - 'perfect' transcription
# * an audio file, extension can vary (.mp3, .wav, .mp4 etc)

EESEN_ROOT=~/eesen

# Change these if you're using different models 
GRAPH_DIR=$EESEN_ROOT/asr_egs/tedlium/v2-30ms/data/lang_phn_test_test_newlm
MODEL_DIR=$EESEN_ROOT/asr_egs/tedlium/v2-30ms/exp/train_phn_l5_c320_v1s

# Defaults
frame_shift=0.03  # 30 ms frames
lm_weight=0.8     # same as best setting for 30ms eesen tedlium transcriber

. path.sh
. utils/parse_options.sh

filename=$(basename "$1")
basename="${filename%.*}"
dirname=$(dirname "$1")
extension="${filename##*.}"

if [ $# -ne 1 ]; then
  echo "Usage: align.sh <basename>.{wav,mp3,mp4,sph}"
  echo " in same folder is test text named <basename>.txt"
  echo " and STM file named <basename>.stm (for segments)"
  echo " ./align.sh /vagrant/GaryFlake_2010.wav"
  echo " output is build/output/<basename>.ali"
  exit 1;
fi

mkdir -p build/audio/base

# un-shorten-ify SPH files
#if [ $extension == "sph" ]; then
#    sph2pipe $1 > build/audio/base/$basename.unshorten
#    sox build/audio/base/$basename.unshorten -c 1 build/audio/base/$basename.wav rate -v 16k
#fi

mkdir -p src-audio
cp $1 src-audio
make build/audio/base/$basename.wav

# 8k
# sox $1 -c 1 -e signed-integer build/audio/base/$basename.wav rate -v 8k

mkdir -p build/diarization/$basename
# make STM from cha
if [ -f $dirname/$basename.cha -a ! -f $dirname/$basename.stm ]; then
  local/cha2stm.sh $dirname/$basename.cha > $dirname/$basename.stm
fi

# make segments from $1.stm
cat $dirname/$basename.stm | grep -v "inter_segment_gap" | grep -v "ignore_time_segment_in_scoring" | awk '{OFMT = "%.0f"; print $1,$2,$4*100,($5-$4)*100,"M S U",$2}' > build/diarization/$basename/show.seg


# Generate features
rm -rf build/trans/$basename/text
make SEGMENTS=show.seg build/trans/$basename/fbank

# Expect test text in format with utterance IDs per line
uttdata=build/trans/$basename
if [ -f $dirname/$basename.txt ];
  then
    echo "Aligning text found at $dirname/$basename.txt"
    cat $dirname/$basename.txt | awk '{print NR" "$0}' > $uttdata/text
  else
    echo "Aligning text found in $dirname/$basename.stm"
    cat $dirname/$basename.stm | awk '{$1="";$2="";$3="";$4="";$5=""; $6=""; print NR$0}' \
	| sed 's/     //' > $uttdata/text
fi
cp build/diarization/$basename/show.seg $uttdata

#local/align_ctc_multi_utts.sh --acoustic_scale 0.8 $GRAPH_DIR $GRAPH_DIR $uttdata  $MODEL_DIR $uttdata/align
#                                                   <langdir>  <data>     <uttdata> <mdldir>   <dir>
local/align_ctc_multi_utts.sh --acoustic_scale $lm_weight $GRAPH_DIR $GRAPH_DIR $uttdata  $MODEL_DIR $uttdata/align

# Copy results to someplace useful
cp $uttdata/align/ali build/output/$basename.ali

