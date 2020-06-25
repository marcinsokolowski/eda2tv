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
name=cand1015+07
if [[ -n "$3" && "$3" != "-" ]]; then
   name=$3
fi

# fits list file 
list=fits_list_I
if [[ -n "$4" && "$4" != "-" ]]; then
   list=$4
fi

export PATH=~/Software/eda2tv/source_finder/:$PATH

path=`which dump_pixel_radec.py`


# ls *_I.fits > fits_list_I_tmp

echo "python $path $list --ra=${ra} --dec=${dec} --calc_rms --outfile=sgr1935+2154.txt --min_elevation=15 --radius=3"
python $path $list --ra=${ra} --dec=${dec} --calc_rms --outfile=sgr1935+2154.txt --min_elevation=15 --radius=3

# echo "rm -f fits_list_I_tmp"
# rm -f fits_list_I_tmp

