#!/bin/bash
#
# makescores.sh
#
# script to compute weighted average WER across all speakers in a TEDLIUM score set 
# found in build/trans/<speaker>/eesen/decode/score_N/ where there's
# a folder for each <speaker> and N is in the range {min_acwt..max_acwt}

min_acwt=5
max_acwt=10
for i in {5..10}
do
    # compute total word count
    totalwords=`cat build/trans/*/eesen/decode/score_$i/*.sys | grep -e "_" | grep -v ctm | sed -e 's/|//g' | sed -e 's/  / /g' | sed -e 's/  / /g'| sed -e 's/  / /g' | awk '{print $3}' | paste -sd+ - | bc`
    echo "ACWEIGHT" $i
    echo " SPKR Snt Wrd Corr Sub Del Ins Err S.Err NCE"
    cat `find build/trans/*/eesen/decode/score_$i -name \*.sys` | grep -e "_" | grep -v ctm | sed -e 's/|//g' | sed -e 's/  / /g' | sed -e 's/  / /g'
    echo

    echo " Weighted AVG WER" `cat $(find build/trans/*/eesen/decode/score_$i -name \*.sys) | grep -e "_" | grep -v ctm | sed -e 's/|//g' | sed -e 's/  / /g' | sed -e 's/  / /g' | awk -v S=$totalwords '{print $8 * $3/S}' | paste -sd+ - | bc`
    echo

done
