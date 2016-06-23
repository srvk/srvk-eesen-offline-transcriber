#!/bin/bash
#
# Shell script to run eesen offline transcriber on TEDLIUM test data
# and produce scoring data. Takes as input a pair of corpus files, e.g.
# GaryFlake_2010.stm and GaryFlake_2010.sph
# 

if [ $# -ne 1 ]; then
  echo "Usage: run-scored.sh <basename>"
  echo "where <basename> is the basename of files somewhere with"
  echo "extensions .stm and .sph"
  echo
  echo "./run-scored-8k-x3.sh /vagrant/eval2000/english/sw_4484.sph"
  exit 1;
fi

filename=$(basename "$1")
dirname=$(dirname "$1")
extension="${filename##*.}"
basename="${filename%.*}"

mkdir -p build/audio/base

sox $dirname/$basename.sph -e signed-integer build/audio/base/$basename.wav rate -v 8k

mkdir -p build/diarization/$basename

# 8k
#make segments from $1.stm
if [ -f $dirname/../stm ]; then
  grep -v "inter_segment_gap" $dirname/../stm | grep -v ';;' | grep -e $basename | awk '{OFMT = "%.0f"; print $1,$2,$4*100,($5-$4)*100,"M S U",$2}' > build/diarization/$basename/show.seg
else
  grep -v "inter_segment_gap" $dirname/$basename.stm | grep -v ';;' | grep -e $basename | awk '{OFMT = "%.0f"; print $1,$2,$4*100,($5-$4)*100,"M S U",$2}' > build/diarization/$basename/show.seg
fi

make -f Makefile-x3 SEGMENTS=show.seg build/trans/$basename/wav.scp

if [ -f $dirname/../stm ]; then
  cat $dirname/../stm | grep -e ${basename}  >  build/trans/${basename}/stm
else
  cat $dirname/${basename}.stm | grep -e ${basename}  >  build/trans/${basename}/stm
fi

if [ -f $dirname/../glm ]; then
  cp $dirname/../glm build/trans/$basename
else
  cp glm build/trans/$basename
fi

# this will give an error but ignore it
make -f Makefile-x3 build/output/$basename.{txt,trs,ctm,sbv,srt,labels}

# now combine results using ROVER
rover -h build/trans/$basename/eesen/decode_0/score_7/$basename.ctm ctm -h build/trans/$basename/eesen/decode_1/score_7/$basename.ctm ctm -h build/trans/$basename/eesen/decode_2/score_7/$basename.ctm ctm -o build/trans/$basename/rover.ctm -m meth1 >& /dev/null

# score
hubscr.pl -p ~/eesen/tools/sctk/bin -V -l english -h hub5 -g build/trans/$basename/glm -r build/trans/$basename/eesen/decode_0/score_6/stm build/trans/$basename/rover.ctm

#print scores
echo "INPUT"
for f in `ls build/trans/$basename/eesen/decode_*/score_7/*.sys`; do
  head -11 $f | tail -1
done
echo "COMBINED"
head -11 build/trans/$basename/rover.ctm.filt.sys | tail -1

