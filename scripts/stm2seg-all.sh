#!/bin/bash

# this script converts a number of STM files (in upmc-stm/<f>)
# into a segmentation file (in build/diarization/<f>/show.stm

# run multiple times to replace _c, _l, _r (also change stm2seg.sh)

for f in `ls upmc-stm/*.stm`; do
    n=`basename $f .stm`
    echo $n
    mkdir -p build/diarization/${n}_l
    cat $f | ./stm2seg.sh "_l" > build/diarization/${n}_l/show.stm
done

echo ok
