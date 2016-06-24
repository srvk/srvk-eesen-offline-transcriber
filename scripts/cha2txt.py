#!/usr/bin/env python
import sys,subprocess

filename = sys.argv[1].replace(".cha.chatmp","")
stmfile = open(filename+".stm", 'w')
filename = filename[filename.rfind("/")+1:]

sys.stdout.write("processing "+filename+"\n")

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
        stmfile.write( filename+" "+speaker+" "+filename+"_"+speaker+" "+\
                           "{0:.3f}".format(float(time1)/1000)+" "+"{0:.3f}".format(float(time2)/1000))
        # call subprocess shell script to sanitize CHA strings
        tmpfile = open("/tmp/chatmp.txt", 'w')
        for i in range(1,len(splits)-1):
            tmpfile.write(" "+splits[i])
        tmpfile.write("\n")
        tmpfile.close()
        result = subprocess.check_output(["local/stripcha.sh", "/tmp/chatmp.txt"]);
        if result == " \n" or result == "":
            stmfile.write(" (%HESITATION)\n");
        else:
            stmfile.write(result);

stmfile.close()
