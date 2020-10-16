#!/bin/bash


# j2000; circle 214.50333205 -25.97137977 60'
# UT-DATE-TIME SAT_RA[deg] SAT_DEC[deg] AZIM[deg] ELE[deg] ALT[km] UXTIME SATTNAME HA[deg] GeoStat[flag] X Y
# 20201007_023000 162.35500595 -00.56596207 343.26167756 060.34773133 00035893.115 1602037800 Unknown_100202                 008.19202331 1 -1000 -1000


fits=chan_184_20201007T044001_I_diff.fits
if [[ -n "$1" && "$1" != "-" ]]; then
   fits=$1
fi

satfile=filtered_minelev60deg.txt
if [[ -n "$2" && "$2" != "-" ]]; then
   satfile=$2
fi

out_reg=${fits%%fits}reg
if [[ -n "$3" && "$3" != "-" ]]; then
   out_reg=$3
fi


utc_grep=`echo $fits| awk '{utc=substr($1,10,15);utc_grep=substr($1,10,13);gsub("T","_",utc_grep);print utc_grep;}'`

grep $utc_grep $satfile | awk '{printf("j2000; circle %.8f %.8f 1 # %s\n",$2,$3,$8);}' > $out_reg


