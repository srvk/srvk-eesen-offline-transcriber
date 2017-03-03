SHELL := /bin/bash

# Use this file to override various settings
-include /vagrant/Makefile.options

# Set to 'yes' if you want to do speaker ID for trs files
DO_SPEAKER_ID?=no
SID_THRESHOLD?=13

# Some audio produces no results (can't be segmented), or transcribes better
# when segmented differently
# Changing SEGMENTS to one of these values gives more flexibilty;
# (see http://www-lium.univ-lemans.fr/diarization/doku.php/quick_start)
#
#    show.seg       : default - final segmentation with NCLR/CE clustering
#    show.i.seg     : initial segmentation (entire audio)
#    show.pms.seg   : sPeech/Music/Silence segmentation (don't use)
#    show.s.seg     : GLR based segmentation, make Small segments
#    show.l.seg     : linear clustering (merge only side by side segments)
#    show.h.seg     : hierarchical clustering
#    show.d.seg     : viterbi decoding
#    show.adj.h.seg : boundaries adjusted
#    show.flt1.seg  : filter spk segmentation according to pms segmentation
#    show.flt2.seg  : filter spk segmentation according to pms segmentation
#    show.spl.seg   : segments longer than 20 sec are split
#    show.spl10.seg : segments longer than 10 sec are split
#    show.g.seg     : the gender and the bandwith are detected
SEGMENTS ?= show.seg

# Where is Kaldi root directory?
KALDI_ROOT?=~/eesen

GRAPH_DIR?=$(EESEN_ROOT)/asr_egs/tedlium/v1/data/lang_phn_test
MODEL_DIR?=$(EESEN_ROOT)/asr_egs/tedlium/v1/exp/train_phn_l5_c320

# How many processes to use for one transcription task
# must be less than number of speakers, which for lium segmentation is often only 1
njobs ?= 1

# How many threads to use in each process
#nthreads ?= 1

# add Kaldi binaries to path
PATH := utils:$(KALDI_ROOT)/src/bin:$(KALDI_ROOT)/tools/openfst/bin:$(KALDI_ROOT)/src/fstbin/:$(KALDI_ROOT)/src/gmmbin/:$(KALDI_ROOT)/src/featbin/:$(KALDI_ROOT)/src/lm/:$(KALDI_ROOT)/src/sgmmbin/:$(KALDI_ROOT)/src/sgmm2bin/:$(KALDI_ROOT)/src/fgmmbin/:$(KALDI_ROOT)/src/latbin/:$(KALDI_ROOT)/src/nnetbin:$(KALDI_ROOT)/src/nnet2bin/:$(KALDI_ROOT)/src/kwsbin:$(KALDI_ROOT)/src/ivectorbin:$(PATH)
# add EESEN binaries to path
PATH := $(EESEN_ROOT)/src/decoderbin:$(EESEN_ROOT)/src/featbin:$(EESEN_ROOT)/src/nnetbin:$(PATH)
export train_cmd=run.pl
export decode_cmd=run.pl
export cuda_cmd=run.pl
export mkgraph_cmd=run.pl

# optimum experimentally determined LM weight for TEDLIUM data set
# (produces lowest WER)
LM_SCALE?=8

# Find out where this Makefile is located (this is not really needed)
where-am-i = $(lastword $(MAKEFILE_LIST))
THIS_DIR := $(shell dirname $(call where-am-i))

# This ends up just being a folder name for output
FINAL_PASS=eesen

#LD_LIBRARY_PATH=$(KALDI_ROOT)/tools/openfst/lib

.SECONDARY:
.DELETE_ON_ERROR:

export

# Call this (once) before using the system
.init: .kaldi #.lang .composed_lms

.kaldi:
	rm -f steps utils
	ln -fs $(KALDI_ROOT)/egs/wsj/s5/steps
	ln -fs $(KALDI_ROOT)/egs/wsj/s5/utils
	ln -fs $(KALDI_ROOT)/egs/sre08/v1/sid
	mkdir -p src-audio

build/audio/base/%.wav: src-audio/%.sph
	mkdir -p `dirname $@`
	sox $^ build/audio/base/$*.wav rate -v $(sample_rate) #channels 1

build/audio/base/%.wav: src-audio/%.wav
	mkdir -p `dirname $@`
	sox $^ -c 1 -2 build/audio/base/$*.wav rate -v $(sample_rate)

build/audio/base/%.wav: src-audio/%.mp3
	mkdir -p `dirname $@`
	sox $^ -c 1 build/audio/base/$*.wav rate -v $(sample_rate)

build/audio/base/%.wav: src-audio/%.ogg
	mkdir -p `dirname $@`
	sox $^ -c 1 build/audio/base/$*.wav rate -v $(sample_rate)

build/audio/base/%.wav: src-audio/%.mp2
	mkdir -p `dirname $@`
	sox $^ -c 1 build/audio/base/$*.wav rate -v $(sample_rate)

build/audio/base/%.wav: src-audio/%.m4a
	mkdir -p `dirname $@`
	avconv -i $^ -ac 1 -ar $(sample_rate) -y $@
#	ffmpeg -i $^ -f sox - | sox -t sox - -c 1 -2 $@ rate -v $(sample_rate)

build/audio/base/%.wav: src-audio/%.mp4
	mkdir -p `dirname $@`
#	sox $^ -c 1 build/audio/base/$*.wav rate -v $(sample_rate)
	avconv -i $^ -ac 1 -ar $(sample_rate) -y $@ 
	echo "converted audio"
	date +%s%N | cut -b1-13

build/audio/base/%.wav: src-audio/%.flac
	mkdir -p `dirname $@`
	sox $^ -c 1 build/audio/base/$*.wav rate -v $(sample_rate)

build/audio/base/%.wav: src-audio/%.amr
	mkdir -p `dirname $@`
	amrnb-decoder $^ $@.tmp.raw
	sox -s -2 -c 1 -r 8000 $@.tmp.raw -c 1 build/audio/base/$*.wav rate -v $(sample_rate)
	rm $@.tmp.raw

build/audio/base/%.wav: src-audio/%.mpg
	mkdir -p `dirname $@`
	avconv -i $^ -f sox - | sox -t sox - -c 1 -2 build/audio/base/$*.wav rate -v $(sample_rate)
#	ffmpeg -i $^ -f sox - | sox -t sox - -c 1 -2 build/audio/base/$*.wav rate -v $(sample_rate)

# Speaker diarization
build/diarization/%/$(SEGMENTS): build/audio/base/%.wav
	rm -rf `dirname $@`
	mkdir -p `dirname $@`
	echo "$* 1 0 1000000000 U U U 1" >  `dirname $@`/show.uem.seg;
	./scripts/diarization.sh $^ `dirname $@`/show.uem.seg $(SEGMENTS);
	echo "diarization complete"
	date +%s%N | cut -b1-13

#build/audio/segmented/%: build/diarization/%/show.seg
build/audio/segmented/%: build/diarization/%/$(SEGMENTS)
	rm -rf $@
	mkdir -p $@
	cat $^ | cut -f 3,4,8 -d " " | \
	while read LINE ; do \
		start=`echo $$LINE | cut -f 1 -d " " | perl -npe '$$_=$$_/100.0'`; \
		len=`echo $$LINE | cut -f 2 -d " " | perl -npe '$$_=$$_/100.0'`; \
		sp_id=`echo $$LINE | cut -f 3 -d " "`; \
		timeformatted=`echo "$$start $$len" | perl -ne '@t=split(); $$start=$$t[0]; $$len=$$t[1]; $$end=$$start+$$len; printf("%08.3f-%08.3f\n", $$start,$$end);'` ; \
		if [ $${sp_id} == 'A' ]; then \
			sox build/audio/base/$*.wav -c 1  $@/$*_$${timeformatted}_$${sp_id}.wav trim $$start $$len remix 1; \
		elif [ $${sp_id} == 'B' ]; then \
			sox build/audio/base/$*.wav -c 1  $@/$*_$${timeformatted}_$${sp_id}.wav trim $$start $$len remix 2; \
		else \
			sox build/audio/base/$*.wav --norm $@/$*_$${timeformatted}_$${sp_id}.wav trim $$start $$len; \
		fi \
	done

build/trans/%/wav.scp: build/audio/segmented/%
	mkdir -p `dirname $@`
	/bin/ls $</*.wav  | \
		perl -npe 'chomp; $$orig=$$_; s/.*\/(.*)_(\d+\.\d+-\d+\.\d+)_(.*)\.wav/\1-\3---\2/; $$_=$$_ .  " $$orig\n";' | LC_ALL=C sort > $@

build/trans/%/utt2spk: build/trans/%/wav.scp
	cat $^ | perl -npe 's/\s+.*//; s/((.*)---.*)/\1 \2/' > $@

build/trans/%/spk2utt: build/trans/%/utt2spk
	utils/utt2spk_to_spk2utt.pl $^ > $@


# FBANK calculation
#   example target: 
#	make build/trans/myvideo/fbank
#   note the % pattern matches e.g. myvideo
build/trans/%/fbank: build/trans/%/spk2utt
	rm -rf $@
	steps/$(fbank).sh --fbank-config conf/fbank.$(sample_rate).conf --cmd "$$train_cmd" --nj 1 \
		build/trans/$* build/trans/$*/exp/make_fbank $@ || exit 1
	steps/compute_cmvn_stats.sh build/trans/$* build/trans/$*/exp/make_fbank $@ || exit 1
	echo "feature generation done"
	date +%s%N | cut -b1-13


### Decode with Eesen 
# example target
#	make build/trans/myvideo/eesen/decode/log
build/trans/%/eesen/decode/log: build/trans/%/spk2utt build/trans/%/fbank
	rm -rf build/trans/$*/eesen && mkdir -p build/trans/$*/eesen
#	(cd build/trans/$*/eesen; for f in $(MODEL_DIR)/*; do ln -s $$f; done)
	steps/decode_ctc_lat.sh --cmd "$$decode_cmd" --nj $(njobs) --beam 17.0 \
	--lattice_beam 8.0 --max-active 5000 --skip_scoring true \
	--acwt $(ACWT) $(GRAPH_DIR) build/trans/$* `dirname $@` $(MODEL_DIR) || exit 1;

# scoring can happen here now, get_ctm_conf.sh only scores if -f build/trans/$*/stm
# produces confidence scores
# e.g. make build/trans/myvideo/eesen/decode/.ctm
# % = build/trans/myvideo/eesen
%/decode/.ctm: %/decode/log
#	local/get_ctm.sh `dirname $*` $*/graph $*/decode
#	local/get_ctm_conf.sh `dirname $*` $*/graph $*/decode
	local/get_ctm_conf.sh `dirname $*` $(GRAPH_DIR) $*/decode
	touch -m $@

# % = myvideo/eesen
# e.g. make build/trans/myvideo/eesen.segmented.splitw2.ctm
build/trans/%.segmented.splitw2.ctm: build/trans/%/decode/.ctm
#	cat build/trans/$*/decode/score_$(LM_SCALE)/`dirname $*`.ctm | perl -npe 's/(.*)-(S\d+)---(\S+)/\1_\3_\2/' > $@
	cat build/trans/$*/decode/score_$(LM_SCALE)/`dirname $*`.ctm | perl -npe 's/(.*)-(\w+)---(\S+)/\1_\3_\2/' > $@


#build/trans/myvideo/eesen.segmented.splitw2.ctm -> build/trans/myvideo/eesen.segmented.with-compounds.ctm
%.with-compounds.ctm: %.splitw2.ctm
	cat $*.splitw2.ctm > $@

#build/trans/myvideo/eesen.segmented.with-compounds.ctm -> build/trans/myvideo/eesen.segmented.ctm
%.segmented.ctm: %.segmented.with-compounds.ctm
	cat $^ > $@

%.ctm: %.segmented.ctm
	cat $^ | python scripts/unsegment-ctm.py | LC_ALL=C sort -k 1,1 -k 3,3n -k 4,4n > $@

%.with-compounds.ctm: %.segmented.with-compounds.ctm
	cat $^ | python scripts/unsegment-ctm.py | LC_ALL=C sort -k 1,1 -k 3,3n -k 4,4n > $@

%.hyp: %.segmented.ctm
	cat $^ | python scripts/segmented-ctm-to-hyp.py > $@

ifeq "yes" "$(DO_SPEAKER_ID)"
build/trans/%/$(FINAL_PASS).trs: build/trans/%/$(FINAL_PASS).hyp build/trans/%/sid-result.txt
	cat build/trans/$*/$(FINAL_PASS).hyp | python scripts/hyp2trs.py --sid build/trans/$*/sid-result.txt > $@
else
build/trans/%/$(FINAL_PASS).trs: build/trans/%/$(FINAL_PASS).hyp
	cat $^ | python scripts/hyp2trs.py > $@
endif

%.sbv: %.hyp
	cat $^ | python scripts/hyp2sbv.py > $@

%.txt: %.hyp
	cat $^  | perl -npe 'use locale; s/ \(\S+\)/\./; $$_= ucfirst();' > $@

%.srt: %.ctm
	cat $^ | python scripts/ctm2srt.py > $@

%.labels: %.ctm
	cat $^ | python scripts/ctm2labels.py > $@

build/output/%.trs: build/trans/%/$(FINAL_PASS).trs	
	mkdir -p `dirname $@`
	cp $^ $@
	echo "final output done"
	date +%s%N | cut -b1-13

build/output/%.ctm: build/trans/%/$(FINAL_PASS).ctm 
	mkdir -p `dirname $@`
	cp $^ $@

build/output/%.txt: build/trans/%/$(FINAL_PASS).txt
	mkdir -p `dirname $@`
	cp $^ $@

build/output/%.with-compounds.ctm: build/trans/%/$(FINAL_PASS).with-compounds.ctm
	mkdir -p `dirname $@`
	cp $^ $@

build/output/%.sbv: build/trans/%/$(FINAL_PASS).sbv
	mkdir -p `dirname $@`
	cp $^ $@

build/output/%.srt: build/trans/%/$(FINAL_PASS).ctm
	mkdir -p `dirname $@`
	cp $^ $@

build/output/%.ali: build/trans/%/$(FINAL_PASS).txt
	mkdir -p `dirname $@`
	./run_align.sh --GRAPH_DIR $(GRAPH_DIR) --MODEL_DIR $(MODEL_DIR) $*

### Speaker ID stuff
# i-vectors for each speaker in our audio file
build/trans/%/ivectors: build/trans/%/mfcc
	sid/extract_ivectors.sh --cmd "$$decode_cmd" --nj $(njobs) \
		$(THIS_DIR)/kaldi-data/extractor_2048_top500 build/trans/$* $@

# a cross product of train and test speakers
build/trans/%/sid-trials.txt: build/trans/%/ivectors
	cut -f 1 -d " " $(THIS_DIR)/kaldi-data/ivectors_train_top500/spk_ivector.scp | \
	while read a; do \
		cut -f 1 -d " " build/trans/$*/ivectors/spk_ivector.scp | \
		while read b; do \
			echo "$$a $$b"; \
		done ; \
	done > $@

# similarity scores
build/trans/%/sid-scores.txt: build/trans/%/sid-trials.txt
	ivector-plda-scoring \
		"ivector-copy-plda --smoothing=0.0 $(THIS_DIR)/kaldi-data/ivectors_train_top500/plda - |" \
		"ark:ivector-subtract-global-mean scp:$(THIS_DIR)/kaldi-data/ivectors_train_top500/spk_ivector.scp ark:- |" \
		"ark:ivector-subtract-global-mean scp:build/trans/$*/ivectors/spk_ivector.scp ark:- |" \
   build/trans/$*/sid-trials.txt $@

# pick speakers above the threshold
build/trans/%/sid-result.txt: build/trans/%/sid-scores.txt
	cat build/trans/$*/sid-scores.txt | sort -u -k 2,2  -k 3,3nr | sort -u -k2,2 | \
	awk 'int($$3)>=$(SID_THRESHOLD)' | perl -npe 's/(\S+) \S+-(S\d+) \S+/\2 \1/; s/-/ /g' > $@


# Meta-target that deletes all files created during processing a file. Call e.g. 'make .etteytlus2013.clean
.%.clean:
	rm -rf build/audio/base/$*.wav build/audio/segmented/$* build/diarization/$* build/trans/$*
#	rm -rf build/audio/base/$*.wav build/audio/segmented/$* build/diarization/$* build/trans/$* #src-audio/$*.wav

# Also deletes the output files	
.%.cleanest: .%.clean
	rm -rf build/output/$*.{trs,txt,ctm,with-compounds.ctm,sbv,ali,labels}
