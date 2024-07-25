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

if [[ -s radio_sources.txt || -s ~/github/eda2tv/source_finder/radio_sources.txt ]]; then
   if [[ ! -s radio_sources.txt ]]; then
      echo "cp ~/github/eda2tv/source_finder/radio_sources.txt ."
      cp ~/github/eda2tv/source_finder/radio_sources.txt .
   fi

   echo "INFO : using local file radio_sources.txt to monitor radio sources:"
   cat radio_sources.txt
   
   while read line    
   do      
      name=`echo $line | awk '{print $1;}'`
      
      if [[ $name != "#" ]]; then
         ra_deg=`echo $line | awk '{print $2;}'`
         dec_deg=`echo $line | awk '{print $3;}'`
         fits_list=`echo $line | awk '{print $4;}'`
         reference=`echo $line | awk '{print $5;}'`

         echo "Monitoring source $name at ($ra_deg,$dec_deg) [deg] and slightly OFF position:"

         if [[ $reference -gt 0 ]]; then
            echo "monitor_source_and_ref_radec.sh ${ra_deg} ${dec_deg} ${name} - 1"
            monitor_source_and_ref_radec.sh ${ra_deg} ${dec_deg} ${name} - 1
         else
            echo "monitor_source_radec.sh ${ra_deg} ${dec_deg} ${name} ${fits_list} \"--use_weighting\""
            monitor_source_radec.sh ${ra_deg} ${dec_deg} ${name} ${fits_list} "--use_weighting"
         fi
      else
         echo "DEBUG : comment line |$line| skipped"
      fi
   done < radio_sources.txt
else
   echo "WARNING : monitoring default list of sources"

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
fi


echo "rm -f fits_list_I_tmp"
rm -f fits_list_I_tmp

