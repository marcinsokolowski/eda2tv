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

# fits list file 
list=fits_list_I
if [[ -n "$4" && "$4" != "-" ]]; then
   list=$4
fi

options=""
if [[ -n "$5" && "$5" != "-" ]]; then
   options=$5
fi

min_elevation=15
if [[ -n "$6" && "$6" != "-" ]]; then
   min_elevation=$6
fi

radius_deg=3
if [[ -n "$7" && "$7" != "-" ]]; then
   radius_deg=$7
fi

outfile=${name}.txt
if [[ -n "$8" && "$8" != "-" ]]; then
   outfile=$8
fi


export PATH=~/Software/eda2tv/source_finder/:$PATH

path=`which dump_pixel_radec.py`


# ls *_I.fits > fits_list_I_tmp

echo "python $path $list --ra=${ra} --dec=${dec} --calc_rms --outfile=${outfile} --min_elevation=${min_elevation} --radius=${radius_deg} --last_processed_filestamp=${name}.last_processed_file ${options}"
python $path $list --ra=${ra} --dec=${dec} --calc_rms --outfile=${outfile} --min_elevation=${min_elevation} --radius=${radius_deg} --last_processed_filestamp=${name}.last_processed_file ${options}

# echo "rm -f fits_list_I_tmp"
# rm -f fits_list_I_tmp

