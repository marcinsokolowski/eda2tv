#!/bin/bash

min_elev=0
if [[ -n "$1" && "$1" != "-" ]]; then
   min_elev=$1
fi

outfile=filtered_minelev${min_elev}deg.txt
if [[ -n "$2" && "$2" != "-" ]]; then
   outfile=$2
fi


idx=0

# 1602028800
for file in `ls ??????????.txt`
do
   if [[ $idx == 0 ]]; then
      head -1 $file > ${outfile}
   fi
   
   awk -v min_elev=${min_elev} '{if($5>min_elev){print $0;}}' $file >> ${outfile}

   idx=$(($idx+1))
done


# filter some most interesting ones :
grep ISS ${outfile} > ${outfile}.ISS
grep HST ${outfile} > ${outfile}.HST
grep KAITUO ${outfile} > ${outfile}.KAITUO
grep BGUSAT ${outfile} > ${outfile}.BGUSAT
grep BUGSAT ${outfile} > ${outfile}.BUGSAT
