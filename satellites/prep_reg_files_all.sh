#!/bin/bash

fitslist=list_I_diff
if [[ -n "$1" && "$1" != "-" ]]; then
   fitslist=$1
fi

satfile=filtered_minelev60deg.txt
if [[ -n "$2" && "$2" != "-" ]]; then
   satfile=$2
fi


for fits in `cat $fitslist`
do
   echo "prep_reg_files.sh $fits $satfile"
   prep_reg_files.sh $fits $satfile
done
