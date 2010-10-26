#!/bin/sh

SRC=$1
REF=$2
TEST=$3

if [[ $# -ne 3 ]]
then
  echo "Error: Wrong number of parameters"
  echo "USAGE: pwer.sh source reference test"
  exit 1
fi

apertium-eval-translator-line.pl -t $TEST -r $REF | grep "(PER)" | awk '{print $6}'

