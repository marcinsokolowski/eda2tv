#!/bin/bash

satfile=filtered_minelev60deg.txt
if [[ -n "$1" && "$1" != "-" ]]; then
   satfile=$1
fi

satname=HST
if [[ -n "$2" && "$2" != "-" ]]; then
   sattname=$2
fi

out_reg=${satfile%%.txt}_${satname}.reg
if [[ -n "$3" && "$3" != "-" ]]; then
   out_reg=$3
fi


# utc_grep=`echo $fits| awk '{utc=substr($1,10,15);utc_grep=substr($1,10,13);gsub("T","_",utc_grep);print utc_grep;}'`

grep $satname $satfile | awk '{printf("j2000; circle %.8f %.8f 1 # %s\n",$2,$3,$1);}' > $out_reg

