#!/bin/bash


export PATH=~/Software/eda2tv/source_finder/:$PATH

path=`which dump_pixel_radec.py`


ls *_I.fits > fits_list_I_tmp

echo "python $path fits_list_I_tmp --ra=293.750 --dec=21.90 --calc_rms --outfile=sgr1935+2154.txt --min_elevation=15"
python $path fits_list_I_tmp --ra=293.750 --dec=21.90 --calc_rms --outfile=sgr1935+2154.txt --min_elevation=15

echo "rm -f fits_list_I_tmp"
rm -f fits_list_I_tmp

