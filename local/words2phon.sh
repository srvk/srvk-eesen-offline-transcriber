#!/bin/bash

# Apache 2.0

# Convert words (in STM format) to pronunciations using CMU Pronouncing Dictionary


filename=$(basename "$1")
dirname=$(dirname "$1")
extension="${filename##*.}"
basename="${filename%.*}"

cp -f $1 words2phon.tmp

printf "UTTERANCE "
curl -s `curl -s -F "wordfile=@words2phon.tmp" http://www.speech.cs.cmu.edu/cgi-bin/tools/logios/lextool.pl | awk ' /DICT/ { print $3 } '` | sed 's/\t/ , /g' | awk '{tab=0; for (i=1; i<=NF; i++) {if ($i==",") tab=1; if ((tab==1) && ($i!=",")) printf($i " ")}; print ""}'

rm -f words2phon.tmp
