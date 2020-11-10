#!/bin/bash

ra=153.90833333
if [[ -n "$1" && "$1" != "-" ]]; then
  ra=$1
fi

dec=7.31083333
if [[ -n "$2" && "$2" != "-" ]]; then
  dec=$2
fi

# 10:15:38 , 7:18:39 
# name=cand1015+07 # echo 153.23342 -7.9 | awk '{h=int($1/15.00);m=(($1/15.00)-h)*60.00;dec_deg=int($2);printf("%d%d%03d\n",h,m,dec_deg);}'
name=`echo "$ra $dec" | awk '{h=int($1/15.00);m=(($1/15.00)-h)*60.00;dec_deg=int($2);printf("cand%d%d%03d\n",h,m,dec_deg);}'`
if [[ -n "$3" && "$3" != "-" ]]; then
   name=$3
fi

options=""
if [[ -n "$4" && "$4" != "-" ]]; then
   options=$4
fi

off=0
if [[ -n "$5" && "$5" != "-" ]]; then
   off=$5
fi

min_elevation=15
off_offset=7


export PATH=~/Software/eda2tv/source_finder/:$PATH

echo "monitor_source_radec.sh $ra $dec ${name}_diff fits_list_I_diff"
monitor_source_radec.sh $ra $dec ${name}_diff fits_list_I_diff

echo "monitor_source_radec.sh $ra $dec ${name} fits_list_I \"--use_weighting\""
monitor_source_radec.sh $ra $dec ${name} fits_list_I "--use_weighting"

if [[ $off -gt 0 ]]; then
   ra_off=`echo $ra | awk -v off_offset=${off_offset} '{prinf("%.8f\n",($1+off_offset));}'`
   dec_off=`echo $dec | awk -v off_offset=${off_offset} '{prinf("%.8f\n",($1+off_offset));}'`
   
   echo "monitor_source_radec.sh $ra_off $dec_off OFF_${name}_diff fits_list_I_diff"
   monitor_source_radec.sh $ra_off $dec_off OFF_${name}_diff fits_list_I_diff
   
   # reference can be 0 degree above horizon :
   echo "monitor_source_radec.sh $ra_off $dec_off OFF_${name}  fits_list_I \"--use_weighting\" 0"
   monitor_source_radec.sh $ra_off $dec_off OFF_${name}  fits_list_I "--use_weighting" 0
fi

