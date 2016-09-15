#!/usr/bin/python
#
# stripchat.py
#
# Merge the alignments back into XML format suitable for CHATTER to turn into CHA format
#
# usage example ./merge_align_cha.py myfile.xml myfile.ali

from xml.dom.minidom import parse
import sys,argparse

reload(sys)
sys.setdefaultencoding("utf-8")

parser=argparse.ArgumentParser(description="""Description""")
parser.add_argument('xmlfile', nargs='?', type=argparse.FileType('r'), help='CHATTER (xml) format output file')
parser.add_argument('alignfile', nargs='?', type=argparse.FileType('r'), help='alignment (.ali) input file')

args=parser.parse_args()

xmlfile = args.xmlfile.name
dom = parse(xmlfile)
utts = dom.getElementsByTagName('u') # utterance tags "<u>"

alignfile = open(args.alignfile.name, 'r')

stopped = False

alignline = alignfile.readline()
aligntime = alignline.split()[0]

timecode = aligntime[aligntime.rfind("---")+3:]

def getTimecode( line ):
    time = line.split()[0]
    return time[time.rfind("---")+3:]

def doWord( thisUtt, word ):
    global stopped
    global timecode
    global alignline
    if (not stopped):
        # insert word timing into DOM (xml)
        mediatag = dom.createElement("internal-media")
        time1 = format(float(alignline.split()[2]), '.3f')
        time2 = format(float(alignline.split()[3]) + float(time1), '.3f')

        mediatag.setAttribute("start", time1)
        mediatag.setAttribute("end", time2)
        mediatag.setAttribute("unit", "s")

        # some alignments have zero length (sorry)
        # CHATTER doesn't like this. Rather than fudge numbers, just
        # leave out this word alignment - cleanest option
        if (time1 != time2):
            thisUtt.insertBefore(mediatag, word.nextSibling)

        alignline = alignfile.readline()
        # handle end of file
        if (alignline == ""):
            stopped = True
            return
        newTimecode = getTimecode(alignline)
        if (newTimecode != timecode):
            timecode = newTimecode
            stopped = True
        else:
            stopped = False

# Read one line at a time from alignfile
# For each unique timestamp, add XML 'bullet' tags for corresponding <u>tterance / <w>ord pair

for utt in utts:
    if (utt.nodeType == utt.ELEMENT_NODE and utt.tagName == "u"):
        stopped = False

        # speaker
        for key in utt.attributes.keys():
            if key == "who":
                speaker=utt.attributes[key].nodeValue
            #spk_reco_clause = recording+" "+speaker+" "+recording+"_"+speaker+" <parse_cha_xml> "

        for word in utt.childNodes:
            # time code
            if word.nodeType == word.ELEMENT_NODE and word.tagName == 'media':
                for key in word.attributes.keys():
                    if key == "start":
                        start = word.attributes[key].nodeValue
                    if key == "end":
                        end = word.attributes[key].nodeValue
                        # media tag happens AFTER <w>ords: process end of utterance

        # tb:wordType ("<w>" tag)
            if word.nodeType == word.ELEMENT_NODE and word.tagName == 'w':
                doWord(utt, word)
        # tb:groupType ("<g>" tag):
            if word.nodeType == word.ELEMENT_NODE and word.tagName == 'g':
                doWord(utt, word)
print dom.toxml()
