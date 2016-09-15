#!/bin/bash

# Copyright 2016  er1k
# Apache 2.0

# Given audio and CHA transcript, generate a new CHA transcript
# with word-level timings, using Eesen decoder & models
# Calls:
#   scripts/parse_cha_xml.py
#   scripts/merge_align_cha.py

filename=$(basename "$1")
basename="${filename%.*}"
dirname=$(dirname "$1")
extension="${filename##*.}"

./align.sh $1
python scripts/merge_align_cha.py $dirname/$basename.xml build/output/$basename.ali >build/trans/$basename/$basename.xml

# convert back to CHA format

 ~/bin/lib/zulu8.17.0.3-jdk8.0.102-linux_x64/bin/java -cp lib/chatter.jar org.talkbank.chatter.App -inputFormat xml -outputFormat cha -output build/output/$basename.cha build/trans/$basename/$basename.xml

