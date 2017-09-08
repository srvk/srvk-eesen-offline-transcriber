#!/bin/bash
#
# Shell script to do speech2text.sh equivalent but use STM or CHA to
# create 'fake' segments, bypassing LIUM segmenter
#
# Takes name of file to process, with .stm or .cha file in same folder
# ./run-segmented.sh myvideo.mp3
#

if [ $# -ne 1 ]; then
  echo "Usage: run-segmented.sh <input filename>"
  echo "where <input filename> is an audio file, and has in the"
  echo "same folder, and with same basename, a .stm or .cha file"
  echo "For example, if inputs are myvideo.mp3 and myvideo.cha"
  echo
  echo "./run-segmented.sh myvideo.mp3"
  exit 1;
fi

filename=$(basename "$1")
dirname=$(dirname "$1")
extension="${filename##*.}"
basename="${filename%.*}"

. path.sh

mkdir -p build/audio/base

# un-shorten-ify SPH files
if [ $extension == "sph" ]; then
    sph2pipe $1 > build/audio/base/$basename.unshorten
    sox build/audio/base/$basename.unshorten -c 1 build/audio/base/$basename.wav rate -v 16k
else
    mkdir -p src-audio
    cp $1 src-audio
    make build/audio/base/$basename.wav
fi

mkdir -p build/diarization/$basename
mkdir -p build/trans/$basename

# decision logic: make STM from various formats, currently .cha

if [ -f $dirname/$basename.cha ]; then
  echo "CHA file found: " $dirname/$basename.cha
  # creates $basename.stm
  local/cha2stm.sh $dirname/$basename.cha > build/trans/$basename/$basename.stm


elif [ -f $dirname/$basename.stm ]; then
  # STM format
  echo "STM file found: " $dirname/$basename.stm
  cp $dirname/$basename.stm build/trans/$basename/
fi

# code from run-scored.sh to create show.seg from .STM
cat build/trans/$basename/$basename.stm | grep -v "inter_segment_gap" | grep -v "ignore_time_segment_in_scoring" | awk '{OFMT = "%.0f"; print $1,$2,$4*100,($5-$4)*100,"M S U",$2}' > build/diarization/$basename/show.seg

make SEGMENTS=show.seg build/output/$basename.{txt,trs,ctm,sbv,srt,labels}

# put phonetic transcription in output folder (not part of Makefile)
#python local/readphonemes.py build/trans/${basename}/eesen/decode/phones.1.txt > build/output/${basename}.phones
