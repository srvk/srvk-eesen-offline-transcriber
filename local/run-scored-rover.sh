#!/bin/bash
#
# Shell script to run eesen offline transcriber on TEDLIUM test data
# and produce scoring data. Takes as input a pair of corpus files, e.g.
# GaryFlake_2010.stm and GaryFlake_2010.sph, or looks one folder up
# from the .sph for a shared stm file

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

. path.sh

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
mkdir -p build/trans/$basename

# make segments from $1.stm
if [ -f $dirname/../stm/$basename.stm ]; then
    echo "Using reference: " $dirname/../stm/$basename.stm
    cp $dirname/../stm/$basename.stm build/trans/$basename/stm
    cat $dirname/../stm/$basename.stm | grep -v "inter_segment_gap" | grep -v "ignore_time_segment_in_scoring" | awk '{OFMT = "%.0f"; print $1,$2,$4*100,($5-$4)*100,"M S U",$2}' > build/diarization/$basename/show.seg
else
    echo "Using reference: " $dirname/$basename.stm
    cp $dirname/$basename.stm build/trans/$basename/stm
    cat $dirname/$basename.stm | grep -v "inter_segment_gap" | grep -v "ignore_time_segment_in_scoring" | awk '{OFMT = "%.0f"; print $1,$2,$4*100,($5-$4)*100,"M S U",$2}' > build/diarization/$basename/show.seg
fi

make -f Makefile-x3 SEGMENTS=show.seg build/trans/$basename/wav.scp

cp glm build/trans/$basename

# this will give an error but ignore it
make -f Makefile-x3 build/output/$basename.{txt,trs,ctm,sbv,srt,labels}

# now combine results using ROVER
rover -h build/trans/$basename/eesen/decode_0/score_7/$basename.ctm ctm -h build/trans/$basename/eesen/decode_1/score_7/$basename.ctm ctm -h build/trans/$basename/eesen/decode_2/score_7/$basename.ctm ctm -o build/trans/$basename/rover.ctm -m meth1

# score the combined output
hubscr.pl -p ~/eesen/tools/sctk/bin -V -l english -h hub5 -g build/trans/$basename/glm -r build/trans/$basename/eesen/decode_0/score_7/stm build/trans/$basename/rover.ctm

#print scores
echo "INPUT"
for f in `ls build/trans/$basename/eesen/decode_*/score_7/*.sys`; do
  head -11 $f | tail -1
done
echo "COMBINED"
head -11 build/trans/$basename/rover.ctm.filt.sys | tail -1


