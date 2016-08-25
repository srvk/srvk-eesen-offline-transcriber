#!/usr/bin/python
#
# stripchat.py
#
# Print out 'only the words' that are found in a CHATTER format (xml) file
# supplied as an argument, or via pipe
#
# To toggle whether UNIBET words are printed out, or instead appear as "<oov">
# set the switch --oov.  To instead print their replacements, set the switch --replacment
#
# usage ./parse_cha_xml.py P1_6W_SE_C6.xml
from xml.dom.minidom import parse
import sys,argparse

parser=argparse.ArgumentParser(description="""Description""")
parser.add_argument('--oov', action='store_true', help='print <oov> symbols for nonwords')
parser.add_argument('--replacement', action='store_true', help='print replacement words')
parser.add_argument('infile', nargs='?', type=argparse.FileType('r'), help='CHATTER (xml) format input file',
                    default=sys.stdin)
args=parser.parse_args()

dom = parse(args.infile)
utts = dom.getElementsByTagName('u') # utterances
oov = args.oov
replacement = args.replacement

for utt in utts:
    for word in utt.childNodes:
        # tb:wordType ("<w>" tag)
        if word.nodeType == word.ELEMENT_NODE and word.tagName == 'w':
            print word.firstChild.nodeValue,

        # tb:groupType ("<g>" tag):
        if word.nodeType == word.ELEMENT_NODE and word.tagName == 'g':
            for group in word.childNodes:
                if group.nodeType == group.ELEMENT_NODE and group.tagName == 'w':
                    if len(group.attributes.keys())==0:
                        # Word has no attributes, can only print the word
                        print group.firstChild.nodeValue,
                    else:
                        # print oov (or unibet encoded word)
                        if oov: print "<oov>",
                        else:
                            for key in group.attributes.keys():
                                if key == "formType" and group.attributes[key].nodeValue == "UNIBET":
                                    if replacement:
                                        for subword in group.childNodes:
                                            if subword.nodeType == subword.ELEMENT_NODE and subword.tagName == 'replacement':
                                                for replacement in subword.childNodes:
                                                    if replacement.nodeType == replacement.ELEMENT_NODE and replacement.tagName == 'w':
                                                        print replacement.firstChild.nodeValue,
                                    else:
                                        print group.firstChild.nodeValue,
    print
