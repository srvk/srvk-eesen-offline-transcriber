#!/usr/bin/env python
#
# readphonemesctm.py
#
# using a map of CMUDict phones, IPA phones, and indices (local/units.txt)
# given the output from CTC decode (decode_ctc_lat) as a list of utterances, each a list of frames, each frame
# containing a vector of likelihoods for each phoneme, produce a sequence
# of phonemes per utterance, squashing repetitions.  Output format: CTM

# Apache 2.0


import sys

# read in map of phoneme indices to phonemes

# set field to 0 for ipa
# or else set it to 1 for CMUDict phones
field=0

dict={}
dict[0] = " "
units = open("local/units.txt", 'r')
for phoneme in units.readlines():
    phoneme = phoneme.replace('\n','').strip()
    fields = phoneme.split(' ')
    dict[int(fields[2])] = fields[field]
units.close()

# iterate through phones file

fread = open(sys.argv[1], 'r')
framesize = sys.argv[2]

lastPrinted = " "
phoneTimeSum = 0.0
uttTimeSum = 0.0
utteranceID = ""

for frame in fread.readlines():
    frame = frame.replace('\n','').strip()
    likelihoods = frame.split(' ')

    if len(likelihoods) == 3:
        # this line contains utterance ID
        splits = likelihoods[0].split('-')
        speakerID = splits[1]
        utteranceID = likelihoods[0] + " " + speakerID + " "
        lastPrinted = " "
        phoneTimeSum = 0.0
        uttTimeSum = 0.0
    else:
        # the last element might be "]"
        if len(likelihoods) == 47:
            del likelihoods[-1:]
            
        max_value = max(likelihoods)
        max_index = likelihoods.index(max_value)

        c = dict[max_index]
        phoneTimeSum = phoneTimeSum + float(framesize)
        if c != lastPrinted:
            if c != " ":
                sys.stdout.write(utteranceID),
                sys.stdout.write(c) #+":"+str(phoneTimeSum),
                sys.stdout.write(" " + str(uttTimeSum) + " " + str(phoneTimeSum) + "\n")
                lastPrinted = c
                uttTimeSum = uttTimeSum + phoneTimeSum
                phoneTimeSum = 0.0

fread.close()
