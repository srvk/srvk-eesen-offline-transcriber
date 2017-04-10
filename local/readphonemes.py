#!/usr/bin/env python

# Apache 2.0

import sys

# read in map of phoneme indices to phonemes

dict={}
dict[0] = " "
units = open("local/units.txt", 'r')
for phoneme in units.readlines():
    phoneme = phoneme.replace('\n','').strip()
    fields = phoneme.split(' ')
    dict[int(fields[1])] = fields[0]
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
