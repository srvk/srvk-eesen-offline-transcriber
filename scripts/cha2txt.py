#!/usr/bin/env python

# For historical purposes (should really be called cha2stm): a first cut
# at a simplistic way to convert CHA to STM format.  In practice this gets
# a lot of things wrong, and cha2stm.sh should be used instead. But this does
# illustrate some of the basics of where to find time markers in CHA files
# and how to print output that looks like STM
import sys,subprocess

filename = sys.argv[1].replace(".cha","")
stmfile = open(filename+".stm", 'w')
recordingname = filename[filename.rfind("/")+1:]

with open(sys.argv[1]) as f:
    lines = f.readlines()

#sys.stdout.write(";; LABEL \"CH\" \"Chat\" \"Child conversations\"")
#sys.stdout.write(";; LABEL \"MOT\" \"Chat\" \"Mother\"")
#sys.stdout.write(";; LABEL \"FAT\" \"Chat\" \"Father\"")
#sys.stdout.write(";; LABEL \"SIB\" \"Chat\" \"Sibling\"")
#sys.stdout.write(";; LABEL \"ELE\" \"Chat\" \"Unidentified\"")
#sys.stdout.write(";; LABEL \"MOT\" \"Chat\" \"Mother\"")

for line in lines:
    if line.startswith("*") and line.endswith("\n"):
        splits = line.split( )
        spkr = splits[0]
        spekr = spkr.replace("*","")
        speaker = spekr.replace(":","")
        timecode = splits[len(splits)-1]
        timecode2 = timecode.replace("","")
        time1 = timecode2.split("_")[0]
        time2 = timecode2.split("_")[1]
        stmfile.write( recordingname+" "+speaker+" "+recordingname+"_"+speaker+" "+\
                           "{0:.3f}".format(float(time1)/1000)+" "+"{0:.3f}".format(float(time2)/1000))
        stmfile.write("\n")
stmfile.close()
