#!/bin/sh

SRC=$1
REF=$2
TEST=$3

if [[ $# -ne 3 ]]
then
  echo "Error: Wrong number of parameters"
  echo "USAGE: bleu.sh source reference test"
  exit 1
fi

function gen_sgm_file {
  # $1=infile
  # $2=tstset|srcset|refset
  # $3=outfile
  # $4=sysid

  echo "<"$2" setid=\"mteval-01\" srclang=\"Source\" trglang=\"Target\">" > $3
  echo "<DOC docid=\"01\" sysid=\""$4"\">" >> $3
  cat  $1 | sed -re "s/[*](\w+)/\1/g" | gawk '{print "<seg>"$0"</seg>"}' >> $3
  echo "</DOC>" >> $3
  echo "</"$2">" >> $3
}


gen_sgm_file $SRC "srcset" $SRC"-"$$".sgm" "APERTIUM"
gen_sgm_file $TEST "tstset" $TEST"-"$$".sgm" "APERTIUM"
gen_sgm_file $REF "refset" $REF"-"$$".sgm" "APERTIUM"

mteval-v11b.pl -b -r $REF-$$.sgm -s $SRC-$$.sgm -t $TEST-$$.sgm | grep "BLEU score" | mawk '{print $4 *100}'

rm -f $SRC"-"$$".sgm" $TEST"-"$$".sgm" $REF"-"$$".sgm"
