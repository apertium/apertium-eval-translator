#!/bin/sh

SRC=$1
REF=$2
TEST=$3

if [[ $# -ne 3 ]]
then
  echo "Error: Wrong number of parameters"
  echo "USAGE: ter.sh source reference test"
  exit 1
fi

function gen_xml_file {
  # $1=infile
  # $2=tstset|srcset|refset
  # $3=outfile
  # $4=sysid

  echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $3
  echo "<!DOCTYPE mteval SYSTEM ftp://jaguar.ncsl.nist.gov/mt/resources/mteval-xml-v1.0.dtd>" >> $3
  echo "<mteval>" >> $3
  echo "<"$2" setid=\"mteval-01\" srclang=\"Source\" trglang=\"Target\">" >> $3
  echo "<doc docid=\"01\" genre=\"newspapers\" sysid=\""$4"\">" >> $3
  cat  $1 | sed -re "s/[*](\w+)/\1/g" | iconv -f latin1 -t utf8 | gawk '{segid++; print "<seg id=\""segid"\">"$0"</seg>"}' >> $3
  echo "</doc>" >> $3
  echo "</"$2">" >> $3
  echo "</mteval>" >> $3
}


cat $REF | sed -re "s/[*](\w+)/\1/g" | iconv -f latin1 -t utf8 | gawk '{id++; print $0" (APERTIUM."id")"}' > /tmp/ref-$$
cat $TEST | sed -re "s/[*](\w+)/\1/g" | iconv -f latin1 -t utf8 | gawk '{id++; print $0" (APERTIUM."id")"}' > /tmp/test-$$

TER=$(java -jar ./tercom.7.2.jar -r /tmp/ref-$$ -h /tmp/test-$$ | grep "TER" | awk '{print $3}')

echo "$TER*100" | bc -l 

rm -f /tmp/ref-$$ /tmp/test-$$
