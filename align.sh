#!/bin/bash

# Copyright 2016  er1k
# Apache 2.0

# Prepare data for, and run align_ctc_utts.sh script that generates word-level alignments
# in an "Eesen Transccriber-centric" way  output is found in build/trans/<basename>/align/ali

# Required inputs:
#
# * a 'hypothesis' text file for which to compute alignments
#
# * an STM file with utterances, timings - 'perfect' transcription
#
# * an audio file

EESEN_ROOT=~/eesen

# Change these if you're using different models 
GRAPH_DIR=$EESEN_ROOT/asr_egs/tedlium/v2-30ms/data/lang_phn_test_test_newlm
MODEL_DIR=$EESEN_ROOT/asr_egs/tedlium/v2-30ms/exp/train_phn_l5_c320_v1s

if [ $# -ne 1 ]; then
  echo "Usage: align.sh <basename>.{wav,mp3,mp4,sph}"
  echo " in same folder is test text named <basename>.txt"
  echo " and STM file named <basename>.stm"
  echo "./align.sh /vagrant/GaryFlake_2010.wav"
  echo "output is build/output/<basename>.ali"
  exit 1;
fi

filename=$(basename "$1")
dirname=$(dirname "$1")
extension="${filename##*.}"
basename="${filename%.*}"

. path.sh
. utils/parse_options.sh

mkdir -p build/audio/base

# un-shorten-ify SPH files
if [ $extension == "sph" ]; then
    sph2pipe $1 > build/audio/base/$basename.unshorten
    sox build/audio/base/$basename.unshorten -c 1 build/audio/base/$basename.wav rate -v 16k
else
    sox $1 -c 1 build/audio/base/$basename.wav rate -v 16k
fi

# 8k
# sox $1 -c 1 -e signed-integer build/audio/base/$basename.wav rate -v 8k

mkdir -p build/diarization/$basename

# make segments from $1.stm
cat $dirname/$basename.stm | grep -v "inter_segment_gap" | grep -v "ignore_time_segment_in_scoring" | awk '{OFMT = "%.0f"; print $1,$2,$4*100,($5-$4)*100,"M S U",$2}' > build/diarization/$basename/show.seg

# Generate features
make SEGMENTS=show.seg build/trans/$basename/fbank

# Expect test text in format with utterance IDs per line
uttdata=build/trans/$basename
cat $dirname/$basename.txt | awk '{print NR" "$0}' > $uttdata/text
#cat $uttdata/eesen.hyp | awk '{last=$NF; $NF=""; print last" "$0}' | sed s/\(//g | sed s/\)//g >$uttdata/text

#local/align_ctc_multi_utts.sh --acoustic_scale 0.8 $GRAPH_DIR $GRAPH_DIR $uttdata  $MODEL_DIR $uttdata/align
#                             <langdir>  <data>     <uttdata> <mdldir>   <dir>
local/align_ctc_multi_utts.sh $GRAPH_DIR $GRAPH_DIR $uttdata  $MODEL_DIR $uttdata/align

# Copy results to someplace useful
cp $uttdata/align/ali build/output/$basename.ali

