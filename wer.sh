#!/bin/sh

SRC=$1
REF=$2
TEST=$3

if [[ $# -ne 3 ]]
then
  echo "Error: Wrong number of parameters"
  echo "USAGE: wer.sh source reference test"
  exit 1
fi

apertium-eval-translator-line -t $TEST -r $REF | grep "(WER)" | awk '{print $5}'

