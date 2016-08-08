#! /usr/bin/python
'''
Created on Oct 4, 2014

@author: fmetze

convert CTM (segmented) to SRT
'''

import sys
import datetime
import re

def printbuf (anfang, ende, text, nummer):
    print nummer
    datetime1 = datetime.datetime.utcfromtimestamp(anfang)
    datetime2 = datetime.datetime.utcfromtimestamp(ende)
    print "%s --> %s" % (datetime1.strftime('%H:%M:%S.%f')[:-3], datetime2.strftime('%H:%M:%S.%f')[:-3])
    print text
    print ''

nummer = 1
for l in sys.stdin:
    
    m = re.match("^(.*) (.*) (\S+) (\S+) (\S+) (.*)$", l)
    if m:
        filename, word = m.group(1, 5)
        channel = int(m.group(2))
        starttime = float(m.group(3))
        duration = float(m.group(4))
        conf = m.group(6)

        if word == '<#s>' and 'text' in vars():
            printbuf (anfang, starttime+duration, text, nummer)
            anfang = starttime
            nummer += 1
            del text
        elif 'text' in vars():
            text = text + ' ' + word
        else:
            text = word
            anfang = starttime

    elif re.match(";.*") or re.match("#.*"):
        pass

    else:
        raise Exception("cannot process line: " + l)

printbuf (anfang, starttime+duration, text, nummer)
