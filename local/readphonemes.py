#!/usr/bin/env python
#
# readphonemes.py
#
# using a map of CMUDict phones, IPA phones, and indices (local/units.txt)
# given the output from CTC decode (decode_ctc_lat) as a list of utterances, each a list of frames, each frame
# containing a vector of likelihoods for each phoneme, produce a sequence
# of phonemes per utterance, squashing repetitions

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

lastPrinted = " "
count = 1

for frame in fread.readlines():
    frame = frame.replace('\n','').strip()
    likelihoods = frame.split(' ')

    if len(likelihoods) == 3:
        print "\nutterance ID: ",
        print likelihoods[0]
        lastPrinted = " "
        count = 1
    else:
        # the last element might be "]"
        if len(likelihoods) == 47:
            del likelihoods[-1:]
            
        max_value = max(likelihoods)
        max_index = likelihoods.index(max_value)

        c = dict[max_index]
        if c == lastPrinted:
            count = count + 1
        else:
            if c != " ":
                # spaces to indicate time duration
                #for i in range(0, count):
                #    sys.stdout.write(' ')
                sys.stdout.write(c) #+":"+str(count),
                sys.stdout.write(" ")
                lastPrinted = c
                count = 1

print
fread.close()
