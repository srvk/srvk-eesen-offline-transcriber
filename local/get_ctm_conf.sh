#!/bin/bash
# Apache 2.0
#
# get_ctm.sh for nnet decode WITHOUT a final.mdl - skips lattice-align-words

[ -f ./path.sh ] && . ./path.sh

# begin configuration section.
cmd=run.pl
stage=0
min_acwt=5
max_acwt=10
acwt_factor=0.1   # the scaling factor for the acoustic scale. The scaling factor for acoustic likelihoods
                 # needs to be 0.5 ~1.0. However, the job submission script can only take integers as the
                 # job marker. That's why we set the acwt to be integers (5 ~ 10), but scale them with 0.1
                 # when they are actually used.
#end configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  echo "Usage: local/get_ctm_conf.sh [--cmd (run.pl|queue.pl...)] <data-dir> <lang-dir|graph-dir> <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --min_acwt <int>                # minumum LM-weight for lattice rescoring "
  echo "    --max_acwt <int>                # maximum LM-weight for lattice rescoring "
  exit 1;
fi

data=$1
lang_or_graph=$2
dir=$3

symtab=$lang_or_graph/words.txt

# assume hubscr.pl is on $PATH
hubscr=$KALDI_ROOT/tools/sctk/bin/hubscr.pl
[ ! -f $hubscr ] && echo "Cannot find scoring program at $hubscr" && exit 1;
hubdir=`dirname $hubscr`

for f in $symtab $dir/lat.*.gz; do
  [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1;
done

name=`basename $data`; # e.g. HVC000037 - base filename of the input data being transcribed


mkdir -p $dir/scoring/log



# We are not using lattice-align-words, which may result in minor degradation 
if [ $stage -le 0 ]; then
     $cmd ACWT=$min_acwt:$max_acwt $dir/scoring/log/get_ctm.ACWT.log \
      mkdir -p $dir/score_ACWT/ '&&' \
      lattice-to-ctm-conf --frame-shift=0.03 --decode-mbr=true --acoustic-scale=ACWT --ascale-factor=$acwt_factor "ark:gunzip -c $dir/lat.*.gz|" - \| \
      utils/int2sym.pl -f 5 $symtab \
      '>' $dir/score_ACWT/$name.ctm || exit 1;
fi

# bail if not scoring
if [ ! -f $data/stm ]; then
    echo "cannot find " $data/stm
    exit 0;
fi

if [ $stage -le 1 ]; then
  # Remove some stuff we don't want to score, from the ctm.
  for x in $dir/score_*/$name.ctm; do
    cp $x $dir/tmpf;
    cat $dir/tmpf | grep -i -v -E '\[NOISE|LAUGHTER|VOCALIZED-NOISE\]' | \
      grep -i -v -E '<UNK>' > $x;
#      grep -i -v -E '<UNK>|%HESITATION' > $x;  # hesitation is scored
  done
fi

# Score the set...
if [ $stage -le 2 ]; then
  # filter the stm to look like it came from transcriber
  # filter skipped lines and convert {space apostrophe} to space
  cat $data/stm | grep -v "inter_segment_gap" | grep -v "ignore_time_segment_in_scoring" | \
      sed -e "s/ '/'/g" > $data/stm.filt

  # make an stm file with labels that match transcriber's (use wav.scp first column)
  cat $data/wav.scp | awk '{print $1}' > $data/wav.cut
  cat $data/stm.filt | cut -d ' ' -f 2- > $data/stm.cut
  sort -k1,1 -k3n $data/stm.cut > $data/stm.sort
  paste -d ' ' $data/wav.cut $data/stm.sort > $data/stm.trans

  $cmd ACWT=$min_acwt:$max_acwt $dir/scoring/log/score.ACWT.log \
    cp $data/stm.trans $dir/score_ACWT/stm '&&' \
    $hubscr -p $hubdir -V -l english -h hub5 -g $data/glm -r $dir/score_ACWT/stm $dir/score_ACWT/${name}.ctm || exit 1;
fi

exit 0;
