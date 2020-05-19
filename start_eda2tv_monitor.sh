#!/bin/bash

export PATH=~/Software/eda2tv/:~/Software/eda2tv/source_finder:~/Software/miriad_scripts:$PATH

correlated_data=1
freq_ch=204
auto_freq=1
imsize=180
station=eda2
start_diff=1
start_monitoring=1

# auto-detect frequency channel :
hdf5_count=`ls *.hdf5 | wc -l`
while [[ $hdf5_count -le 0 ]]; 
do
   echo "PROGRESS : waiting for HDF5 files ..."
   echo "sleep 5"
   sleep 5

   hdf5_count=`ls *.hdf5 | wc -l`   
done


hdf5_file=`ls *.hdf5 | tail -1`
echo "Dectecd hdf5 file $hdf5_file"

if [[ $auto_freq -gt 0 ]]; then
   path=`which hdf5_info.py`
   
   echo "python $path $hdf5_file > first_hdf5_file.hdf5_into"
   python $path $hdf5_file > first_hdf5_file.hdf5_into
   
   channel_id=`grep "Frequency channel" first_hdf5_file.hdf5_into | awk '{print int($4);}'`
   echo "Detected channel_id = $channel_id"
   if [[ $channel_id -gt 0 ]]; then
      freq_ch=$channel_id
      echo "Auto-setting freq_ch = $freq_ch"
   fi
fi

# imsize = 3 x beam_size (could also be 3.75 x beam_size ) :
imsize=`echo $freq_ch | awk '{freq_mhz=$1*(400.00/512.00);D_m=35;pi=3.1415;n_pix_f=(freq_mhz/100.00)*D_m*pi;n_pix_int=int(n_pix_f/10.00);print n_pix_int*10+10;;}'`

echo "##############################################################"
echo "PARAMETERS:"
echo "##############################################################"
echo "correlated_data = $correlated_data"
echo "freq_ch         = $freq_ch"
echo "imsize          = $imsize"
echo "##############################################################"

mkdir -p merged/

if [[ $correlated_data -gt 0 ]]; then 
   echo "Starting eda2tv for correlated data in channel = $freq_ch at :"
   date

   echo "nohup eda2tv_convert_loop.sh ${freq_ch} 0 -1 9.9090430 1 ${station} 1 $imsize \"-a 5\" 1 0 1 > eda2tv.out 2>&1 &"   
   nohup eda2tv_convert_loop.sh ${freq_ch} 0 -1 9.9090430 1 ${station} 1 $imsize "-a 5" 1 0 1 > eda2tv.out 2>&1 &

   echo "sleep 5"   
   sleep 5
else
   echo "ERROR : not yet implemented for data other than correlated"
fi


if [[ $start_diff -gt 0 ]]; then 
   cd merged/
   echo "nohup miriad_diff_images_loop.sh > diff.out 2>&1 &"
   nohup miriad_diff_images_loop.sh > diff.out 2>&1 & 
   cd ..
   
   echo "sleep 5"   
   sleep 5
else
   echo "WARNING : starting of difference script is not required"
fi

if [[ $start_monitoring -gt 0 ]]; then
   cd merged/
   echo "nohup monitor_sources_loop.sh > monitor_sources_loop.out 2>&1 &"
   nohup monitor_sources_loop.sh > monitor_sources_loop.out 2>&1 &
   cd ..

   echo "sleep 5"   
   sleep 5
else
   echo "WARNING : starting of monitoring is not required"
fi

echo "All eda2tv scripts started at :"
date
ps
