#!/usr/bin/python
#
# stripchat.py
#
# Print out 'only the words' that are found in a CHATTER format xml (http://talkbank.org/software/chatter.html)
# supplied as an argument, or via a pipe
#
# To toggle whether UNIBET words are printed out, or instead appear as "<unk>"
# set the switch --oov.  To instead print their replacements, set the switch --replacment
#
# usage ./parse_cha_xml.py P1_6W_SE_C6.xml
from xml.dom.minidom import parse
import sys,argparse

reload(sys)
sys.setdefaultencoding("utf-8")

parser=argparse.ArgumentParser(description="""Description""")
parser.add_argument('--oov', action='store_true', help='print <oov> symbols for nonwords')
parser.add_argument('--replacement', action='store_true', help='print replacement words')
parser.add_argument('--stm', action='store_true', help='produce STM format')
parser.add_argument('infile', nargs='?', type=argparse.FileType('r'), help='CHATTER (xml) format input file',
                    default=sys.stdin)
args=parser.parse_args()
infile = args.infile.name
dom = parse(infile)
utts = dom.getElementsByTagName('u') # utterances
oov = args.oov
stm = args.stm
replacement = args.replacement
recording = infile[infile.rfind("/")+1:]

for utt in utts:
    utterance = ""
    # speaker
    for key in utt.attributes.keys():
        if key == "who":
            speaker=utt.attributes[key].nodeValue
            spk_reco_clause = recording+" "+speaker+" "+recording+"_"+speaker+" "

    for word in utt.childNodes:
        # time code
        if word.nodeType == word.ELEMENT_NODE and word.tagName == 'media':
            for key in word.attributes.keys():
                if key == "start":
                    start = word.attributes[key].nodeValue
                if key == "end":
                    end = word.attributes[key].nodeValue
                    if stm:
                        print spk_reco_clause+start+" "+end+utterance.lower()
                    else: 
                        print utterance.lower()
                    utterance = ""
        # tb:wordType ("<w>" tag)
        if word.nodeType == word.ELEMENT_NODE and word.tagName == 'w':
            for wordlet in word.childNodes:
                if wordlet.nodeType == wordlet.TEXT_NODE:
                    utterance += " "
                    utterance += wordlet.nodeValue.encode('utf8')

        # tb:groupType ("<g>" tag):
        if word.nodeType == word.ELEMENT_NODE and word.tagName == 'g':
            for group in word.childNodes:
                if group.nodeType == group.ELEMENT_NODE and group.tagName == 'w':
                    if len(group.attributes.keys())==0:
                        # Word has no attributes, can only utterance += " " + the word
                        for wordlet in group.childNodes:
                            if wordlet.nodeType == wordlet.TEXT_NODE:
                                utterance += " "
                                utterance += wordlet.nodeValue.encode('utf8')
                    else:
                        # print oov (or unibet encoded word)
                        if oov: utterance += " " + "<unk>"
                        else:
                            for key in group.attributes.keys():
                                if key == "type" and group.attributes[key].nodeValue == "fragment":
                                    utterance += " " + group.firstChild.nodeValue
                                if key == "formType" and group.attributes[key].nodeValue == "UNIBET":
                                    if replacement:
                                        for subword in group.childNodes:
                                            if subword.nodeType == subword.ELEMENT_NODE and subword.tagName == 'replacement':
                                                for replacement in subword.childNodes:
                                                    if replacement.nodeType == replacement.ELEMENT_NODE and replacement.tagName == 'w':
                                                        utterance += " " + replacement.firstChild.nodeValue
                                    else:
                                        utterance += " " + group.firstChild.nodeValue
