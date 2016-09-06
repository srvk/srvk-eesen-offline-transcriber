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
if infile == '<stdin>':
    dom = parse(sys.stdin)
else:
    dom = parse(infile)
utts = dom.getElementsByTagName('u') # utterances
oov = args.oov
stm = args.stm
replace = args.replacement
recording = infile[infile.rfind("/")+1:]
#utterance = ""

# add the word found inside node passed in as argument
def addWord( node ):
    global utterance
    for wordlet in node.childNodes:
        if wordlet.nodeType == wordlet.TEXT_NODE:
            unibet = False
            s = wordlet.nodeValue
            try: s.decode('ascii')
            except UnicodeDecodeError: unibet = True
            utterance += " "
            if oov and unibet:
                utterance += "<unk>"
            else:
                utterance += wordlet.nodeValue.encode('utf8')


def addReplacement ( group ):
    added = False
    for subword in group.childNodes:
        if subword.nodeType == subword.ELEMENT_NODE and subword.tagName == 'replacement':
            for replacement in subword.childNodes:
                if replacement.nodeType == replacement.ELEMENT_NODE and replacement.tagName == 'w':
                    addWord( replacement )
                    added = True
    # didn't find a <replacement> - just output the word
    if not added: addWord( group )

def addUnibetOrReplacement( node ):
    global utterance
    for key in node.attributes.keys():
        if key == "untranscribed":
            if oov:
                utterance += " " + "<unk>"
            else:
                addWord( node )
        if key == "type" and (node.attributes[key].nodeValue == "fragment"):
            utterance += " " + node.firstChild.nodeValue
        if key == "formType" and node.attributes[key].nodeValue == "UNIBET":
            if replace:
                addReplacement( node )
            else:
                addWord( node )

for utt in utts:
    utterance = ""
    # speaker
    for key in utt.attributes.keys():
        if key == "who":
            speaker=utt.attributes[key].nodeValue
            spk_reco_clause = recording+" "+speaker+" "+recording+"_"+speaker+" <parse_cha_xml> "

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
            if len(word.attributes.keys())==0:
                if word.childNodes.length == 1:
                    addWord( word )
                else:
                    if replace:
                        addReplacement( word )
                    else:
                        addWord( word )
            else:
                addUnibetOrReplacement( word )
        # tb:groupType ("<g>" tag):
        if word.nodeType == word.ELEMENT_NODE and word.tagName == 'g':
            for group in word.childNodes:
                if group.nodeType == group.ELEMENT_NODE and group.tagName == 'w':
                    if len(group.attributes.keys())==0:
                        if group.childNodes.length == 1:
                            addWord( group )
                        else:
                            if replace:
                                addReplacement( group )
                            else:
                                addWord( group )
                    else:
                        # print oov (or unibet encoded word)
                        if oov:
                            utterance += " " + "<unk>"
                        else:
                            addUnibetOrReplacement( group )
