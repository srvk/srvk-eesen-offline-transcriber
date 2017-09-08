#!/usr/bin/env python
#
# flatphonemes.py
#
# using a map of CMUDict phones, IPA phones, and indices (local/units.txt)
# given the output of CTC decode as a list of frames, each frame
# containing a vector of likelihoods for each phoneme, produce a sequence
# of phonemes as one long utterance, squashing repetitions, and
# suppressing non-speech sounds ([BRH],[CGH],[NSN],[SMK],[UM],[UHH]) in
# hypothesis (.hyp) format

# Apache 2.0

import sys

# read in map of phoneme indices to phonemes

# set field to 0 for ipa
# or else set it to 1 for CMUDict phones
field=1

dict={}
dict[0] = " "
units = open("local/units.txt", 'r')
for phoneme in units.readlines():
    phoneme = phoneme.replace('\n','').strip()
    fields = phoneme.split(' ')
    dict[int(fields[2])] = fields[field]
units.close()

# print a fake utterance ID to begin the one, long utterance
sys.stdout.write("UTTERANCE")

# iterate through phones file

fread = open(sys.argv[1], 'r')

lastPrinted = " "
eolFlag = False

for frame in fread.readlines():
    frame = frame.replace('\n','').strip()
    likelihoods = frame.split(' ')

    if len(likelihoods) == 3:
        # print utterance ID
        #sys.stdout.write(likelihoods[0])
        lastPrinted = " "
    else:
        # the last frame of an utterance ends with "]"
        # so delete that last element
        if len(likelihoods) == 47:
            del likelihoods[-1:]
            eolFlag = True
            
        max_value = max(likelihoods)
        max_index = likelihoods.index(max_value)

        c = dict[max_index]
        if c != lastPrinted:
            if c != " ":
                # suppress non-speech noises which have
                # indices higher than 6 in units.txt
                if (max_index > 6):
                    sys.stdout.write(" "+c)
                lastPrinted = c

    if eolFlag:
        #sys.stdout.write("\n")
        eolFlag = False
sys.stdout.write("\n")

fread.close()
