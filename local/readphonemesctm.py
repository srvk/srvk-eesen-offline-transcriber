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
oldPhoneme = " "
phoneDuration = 0.0
timeSinceUttBegin = 0.0
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
        phoneDuration = 0.0
        timeSinceUttBegin = 0.0
        phoneStartTime = 0.0
    else:
        # the last element might be "]"
        if len(likelihoods) == 47:
            del likelihoods[-1:]
            
        max_value = max(likelihoods)
        max_index = likelihoods.index(max_value)
        c = dict[max_index]

        # running total
        timeSinceUttBegin += float(framesize)
        if c != lastPrinted and c != oldPhoneme:
            if (oldPhoneme != " "):
                # emit 'old' one
                sys.stdout.write(utteranceID),
                sys.stdout.write(oldPhoneme) #+":"+str(phoneTimeSum),
                # output the 'old' phoneme and compute it's start & cumulative time
                sys.stdout.write(" " + str(phoneStartTime) + " " + str(phoneDuration) + "\n")
                lastPrinted = oldPhoneme
                oldPhoneme = " "

            # new phoneme but might be repeated
            # Save this phoneme as the new 'old' one and save it's start time
            if (c != " "):
                oldPhoneme = c;
                phoneStartTime = timeSinceUttBegin
                phoneDuration = float(framesize);
        elif c == oldPhoneme:
            phoneDuration += float(framesize)

# possibly output the last one
if (oldPhoneme != " "):
    sys.stdout.write(utteranceID),
    sys.stdout.write(oldPhoneme) #+":"+str(phoneTimeSum),
    # output the 'old' phoneme and compute it's start & cumulative time
    sys.stdout.write(" " + str(phoneStartTime) + " " + str(phoneDuration) + "\n")

fread.close()
