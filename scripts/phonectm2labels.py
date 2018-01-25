#! /usr/bin/python
'''
Created on Oct 4, 2014
@author: fmetze,er1k
convert CTM (segmented) phone level transcriptions to Audacity labels format
'''

import sys
import datetime
import re

def printbuf (begin, end, text):
    datetime1 = datetime.datetime.utcfromtimestamp(begin)
    datetime2 = datetime.datetime.utcfromtimestamp(end)
    allseconds1 = 60 * datetime1.minute + 3600 * datetime1.hour + datetime1.second
    allseconds2 = 60 * datetime2.minute + 3600 * datetime2.hour + datetime2.second
    print "%s.%s\t%s.%s\t%s" % (allseconds1, datetime1.strftime('%f'), allseconds2, datetime2.strftime('%f'), text)


for l in sys.stdin:

    m = re.match("^(.*)-(S\d+)---(\S+)-(\S+) (.*) (\S+) (\S+) (.*)$", l)
    if m:
        filename, word = m.group(1, 6)
        speakerid = m.group(2)
        uttstart = float(m.group(3))
        text = word
        phonstart = float(m.group(7))
        duration = float(m.group(8))

        printbuf (uttstart+phonstart, uttstart+phonstart+duration, text)

    else:
        raise Exception("cannot process line: " + l)

printbuf (uttstart+phonstart, uttstart+phonstart+duration, text)
