#!/bin/bash

publish=1 # copy images/movie to the www server 
if [[ -n "$1" && "$1" != "-" ]]; then
   publish=$1
fi

copy_calibration=0
cal_dtm=""
if [[ -n "$2" && "$2" != "-" ]]; then
   copy_calibration=1
   cal_dtm=$2
fi

start_monitoring=1
if [[ -n "$3" && "$3" != "-" ]]; then
   start_monitoring=$3
fi

export PATH=~/Software/eda2tv/:~/Software/eda2tv/source_finder:~/Software/miriad_scripts:$PATH

# integrity checks
if [[ ! -s /opt/aavs/config/station.yml ]]; then
   echo "ERROR : file or symbolic link /opt/aavs/config/station.yml to station config file does not exist -> cannot continue"
   exit
fi

# station=eda2
# station=aavs2
station=`awk -v station_section=0 '{if(index($1,":")>0 && NF==1){if(index($1,"station")>0 ){station_section=1;}else{station_section=0;}}if(station_section>0){if($1=="name:"){station_name=$2;gsub("\"","",station_name);gsub("\r","",station_name);print tolower(station_name);}}}' /opt/aavs/config/station.yml`

correlated_data=1
freq_ch=204
auto_freq=1
imsize=180
start_diff=1
correlator_inttime=1.9818086 
n_avg=1
eda2tv_inttime=`echo $n_avg" "$correlator_inttime | awk '{print ($1*$2);}'`
do_png_rate=10 # convert every 10th image to png 

# difference images on both ?
diff_xy=1
diff_i=1

echo "###################################################"
echo "PARAMETERS :"
echo "###################################################"
echo "station = |$station|"
echo "do_png_rate = $do_png_rate"
echo "publish = $publish"
echo "copy_calibration = $copy_calibration ($cal_dtm)"
echo "###################################################"

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
# n_pix = 3 * ( 180 deg / Beam_size[deg] ) = 3 pi D_m f_mhz / (c_mhz=300) = (freq_mhz/100.00)*D_m*pi
imsize=`echo $freq_ch | awk '{freq_mhz=$1*(400.00/512.00);D_m=35;pi=3.1415;n_pix_f=(freq_mhz/100.00)*D_m*pi;n_pix_int=int(n_pix_f/10.00);print n_pix_int*10+10;;}'`

echo "##############################################################"
echo "PARAMETERS:"
echo "##############################################################"
echo "correlated_data  = $correlated_data"
echo "freq_ch          = $freq_ch"
echo "imsize           = $imsize"
echo "start_monitoring = $start_monitoring"
echo "##############################################################"

mkdir -p merged/
echo $freq_ch >> channel.txt
echo $freq_ch >> merged/channel.txt

if [[ $copy_calibration -gt 0 ]]; then
   echo "DEBUG : copying calibration"
   
   cd merged/
   echo "copy_calibration.sh ${freq_ch} ${cal_dtm}"
   copy_calibration.sh ${freq_ch} ${cal_dtm}
   cd ../
else
   echo "WARNING : copying of calibration is not required - data may not be calibrated properly !!!"
fi


if [[ $correlated_data -gt 0 ]]; then 
   echo "Starting eda2tv for correlated data in channel = $freq_ch at :"
   date

   echo "nohup eda2tv_convert_loop.sh ${freq_ch} 0 -1 $eda2tv_inttime 1 ${station} 1 $imsize \"-a $n_avg\" ${do_png_rate} 0 ${publish} ${copy_calibration} > eda2tv.out 2>&1 &"   
   nohup eda2tv_convert_loop.sh ${freq_ch} 0 -1 $eda2tv_inttime 1 ${station} 1 $imsize "-a $n_avg" ${do_png_rate} 0 ${publish} ${copy_calibration} > eda2tv.out 2>&1 &

   echo "sleep 5"   
   sleep 5
else
   echo "ERROR : not yet implemented for data other than correlated"
fi


if [[ $start_diff -gt 0 ]]; then 
   cd merged/
   
   # diff XX and YY images :
   if [[ $diff_xy -gt 0 ]]; then
      echo "nohup miriad_diff_images_loop.sh > diff.out 2>&1 &"
      nohup miriad_diff_images_loop.sh > diff.out 2>&1 & 
   fi
   
   if [[ $diff_i -gt 0 ]]; then   
      # I images :
      echo "nohup miriad_diff_stokesi_images_loop.sh > miriad_diff_stokesi_images_loop.out 2>&1 &"
      nohup miriad_diff_stokesi_images_loop.sh > miriad_diff_stokesi_images_loop.out 2>&1 &
   fi
   
   cd ..
   
   
   echo "sleep 5"   
   sleep 5
else
   echo "WARNING : starting of difference script is not required"
fi

if [[ $start_monitoring -gt 0 ]]; then   
   cd merged/
   if [[ $start_monitoring -gt 10 ]]; then
      echo "PROGRESS : waiting $start_monitoring seconds for before monitoring started ..."
      echo "sleep $start_monitoring"
      sleep $start_monitoring      
   fi
   
   echo "nohup monitor_sources_loop.sh > monitor_sources_loop.out 2>&1 &"
   nohup monitor_sources_loop.sh > monitor_sources_loop.out 2>&1 &
   
   echo "sleep 5"
   sleep 5
   
   echo "Starting triggering of MWA observations by B0950 acitivity ..."
   echo "nohup trigger_mwa_b0950.sh > trigger_mwa_b0950.log 2>&1 &"
   nohup trigger_mwa_b0950.sh > trigger_mwa_b0950.log 2>&1 &
   
   cd ..

   echo "sleep 5"   
   sleep 5
else
   echo "WARNING : starting of monitoring is not required"
fi

echo "All eda2tv scripts started at :"
date
ps
