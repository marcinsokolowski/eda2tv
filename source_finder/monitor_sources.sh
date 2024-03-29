#!/bin/bash


export PATH=~/Software/eda2tv/source_finder/:$PATH

path=`which dump_pixel_radec.py`


# ls *_I.fits > fits_list_I_tmp

find . -maxdepth 1 -name "chan*_I.fits" | awk '{gsub("./","");print $0;}' | sort > fits_list_I
find . -maxdepth 1 -name "chan*_I_diff.fits" | awk '{gsub("./","");print $0;}' | sort > fits_list_I_diff

# echo "python $path fits_list_I_tmp --ra=293.750 --dec=21.90 --calc_rms --outfile=sgr1935+2154.txt --min_elevation=15 --radius=3 --last_processed_filestamp=sgr1935+2154.last_processed_file"
# python $path fits_list_I_tmp --ra=293.750 --dec=21.90 --calc_rms --outfile=sgr1935+2154.txt --min_elevation=15 --radius=3 --last_processed_filestamp=sgr1935+2154.last_processed_file

# echo "monitor_source_radec.sh 293.750 21.90 sgr1935+2154_diff fits_list_I_diff"
# monitor_source_radec.sh 293.750 21.90 sgr1935+2154_diff fits_list_I_diff

# echo "monitor_source_radec.sh 293.750 21.90 sgr1935+2154 fits_list_I \"--use_weighting\""
# monitor_source_radec.sh 293.750 21.90 sgr1935+2154 fits_list_I "--use_weighting"

echo "monitor_source_and_ref_radec.sh 293.750 21.90 sgr1935+2154 - 1"
monitor_source_and_ref_radec.sh 293.750 21.90 sgr1935+2154 - 1 

echo "monitor_source_radec.sh 148.28875 7.92638889 B0950+08_diff fits_list_I_diff"
monitor_source_radec.sh 148.28875 7.92638889 B0950+08_diff fits_list_I_diff 

echo "monitor_source_radec.sh 148.28875 7.92638889 B0950+08 fits_list_I \"--use_weighting\""
monitor_source_radec.sh 148.28875 7.92638889 B0950+08 fits_list_I "--use_weighting"

# X and Y also to be able to beam correct 
echo "monitor_source_radec.sh 148.28875 7.92638889 B0950+08_XX  fits_list_XX \"--use_weighting\""
monitor_source_radec.sh 148.28875 7.92638889 B0950+08_XX  fits_list_XX "--use_weighting"

echo "monitor_source_radec.sh 148.28875 7.92638889 B0950+08_YY  fits_list_YY \"--use_weighting\""
monitor_source_radec.sh 148.28875 7.92638889 B0950+08_YY  fits_list_YY "--use_weighting"

echo "monitor_source_radec.sh 139.571 -12.1789 2C806_diff fits_list_I_diff"
monitor_source_radec.sh 139.571 -12.1789 2C806_diff fits_list_I_diff

echo "monitor_source_radec.sh 139.571 -12.1789 2C806 fits_list_I \"--use_weighting\""
monitor_source_radec.sh 139.571 -12.1789 2C806 fits_list_I "--use_weighting"

# control lightcurve of an empty patch of the sky as a sanity check and for RMS estimates :
echo "monitor_source_radec.sh 155.075 16.87666667 OFF_B0950+08  fits_list_I \"--use_weighting\""
monitor_source_radec.sh 155.075 16.87666667 OFF_B0950+08  fits_list_I "--use_weighting"

echo "monitor_source_radec.sh 155.075 16.87666667 OFF_B0950+08_diff  fits_list_I_diff"
monitor_source_radec.sh 155.075 16.87666667 OFF_B0950+08_diff  fits_list_I_diff

# Crab pulsar :
echo "monitor_source_radec.sh 83.6334000 22.01444444 B0531+21_diff fits_list_I_diff"
monitor_source_radec.sh 83.6334000 22.01444444 B0531+21_diff fits_list_I_diff

echo "monitor_source_radec.sh 93.6334000 32.01444444 OFF_B0531+21_diff fits_list_I_diff"
monitor_source_radec.sh 93.6334000 32.01444444 OFF_B0531+21_diff fits_list_I_diff

echo "rm -f fits_list_I_tmp"
rm -f fits_list_I_tmp

