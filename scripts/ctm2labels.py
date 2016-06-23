#! /usr/bin/python
'''
Created on Oct 4, 2014
@author: fmetze,er1k
convert CTM (segmented) to Audacity labels format
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

    m = re.match("^(.*) (.*) (\S+) (\S+) (\S+) (.*)$", l)
    if m:
        filename, word = m.group(1, 5)
        channel = int(m.group(2))
        starttime = float(m.group(3))
        duration = float(m.group(4))
        conf = m.group(6)

        if word == '<#s>' and 'text' in vars():
            printbuf (begin, starttime+duration, text)
            begin = starttime
            del text
        elif 'text' in vars():
            text = text + ' ' + word
        else:
            if word != '<#s>': text = word
            begin = starttime

    elif re.match(";.*") or re.match("#.*"):
        pass

    else:
        raise Exception("cannot process line: " + l)

printbuf (begin, starttime+duration, text)
