#!/bin/bash

# Copyright 2016  er1k
# Apache 2.0

# Prepare data for, and run align_ctc_utts.sh script that generates word-level alignments
# in an "Eesen Transccriber-centric" way
# output is found in build/trans/<basename>/align/ali

if [ $# != 1 ]; then
   echo "Wrong #arguments ($#, expected 1)"
   echo "Usage: run_align.sh <basename>"
   echo "       where <basename> is the base name of a file processed by eesen-offline-transcriber"
   echo " e.g.: ./run_align.sh test2"
   echo "output will be in build/trans/<basename>/align/ali"
   exit 1;
fi

EESEN_ROOT=~/eesen

# Change these if you're using different models 
GRAPH_DIR=$EESEN_ROOT/asr_egs/tedlium/v2-30ms/data/lang_phn_test
MODEL_DIR=$EESEN_ROOT/asr_egs/tedlium/v2-30ms/exp/train_phn_l5_c320_v1s

# Generate 'text' format with utterance IDs per line from hypothesis
uttdata=build/trans/$1
cat $uttdata/eesen.hyp | awk '{last=$NF; $NF=""; print last" "$0}' | sed s/\(//g | sed s/\)//g >$uttdata/text

#                                            <langdir>  <data>     <uttdata>      <mdldir>   <dir>
local/align_ctc_utts.sh --acoustic_scale 0.8 $GRAPH_DIR $GRAPH_DIR build/trans/$1 $MODEL_DIR $uttdata/align
