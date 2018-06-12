#!/bin/bash

# this script filters an STM file into a SEG file, suitable for inclusion into diarization
# it also does some checks for length etc

cat - | grep -v ";;" | awk -v e=$1 '{s=$3; gsub(".*_", "", s); if ($5-$4 > 0.1) { printf ("%s%s %s %d %d U U U %s\n", $1, e, $2, $4*100, ($5-$4)*100, s)}}' | grep -v Noises | sed 's/Patient/S1/' | sed 's/Doctor/S0/' | sort -k 8 -k 3n
