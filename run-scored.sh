#!/bin/bash
#
# Shell script to run eesen offline transcriber on TEDLIUM test data
# and produce scoring data. Takes as input a pair of corpus files, e.g.
# GaryFlake_2010.stm and GaryFlake_2010.sph
# 

if [ $# -ne 1 ]; then
  echo "Usage: run-scored.sh <file>"
  echo "where <file> may have extension like .sph .wav .mp3"
  echo
  echo "./run-scored.sh /vagrant/GaryFlake_2010.wav"
  exit 1;
fi

filename=$(basename "$1")
dirname=$(dirname "$1")
extension="${filename##*.}"
basename="${filename%.*}"

mkdir -p build/audio/base

sox $1 -c 1 build/audio/base/$basename.wav rate -v 16k
# 8k
# sox $1 -c 1 -e signed-integer build/audio/base/$basename.wav rate -v 8k

mkdir -p build/diarization/$basename

# make segments from $1.stm
cat $dirname/$basename.stm | grep -v "inter_segment_gap" | grep -v "ignore_time_segment_in_scoring" | awk '{OFMT = "%.0f"; print $1,$2,$4*100,($5-$4)*100,"M S U",$2}' > build/diarization/$basename/show.seg

make SEGMENTS=show.seg build/trans/$basename/wav.scp

cp $dirname/$basename.stm build/trans/$basename/stm
cp glm build/trans/$basename

make build/output/$basename.{txt,trs,ctm,sbv,srt,labels}
