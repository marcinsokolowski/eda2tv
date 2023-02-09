#!/bin/bash

ch=204
if [[ -n "$1" && "$1" != "-" ]]; then
   ch=$1
fi
ch_num=`echo $ch | awk '{printf("%d\n",$1);}'`
freq_mhz=`echo $ch | awk '{printf("%.4f",$1*(400.00/512.00));}'`

voltages=1
if [[ -n "$2" && "$2" != "-" ]]; then
   voltages=$2
fi

process_all=0 # this is a flag <=0 -> process all uvfits files, 1 latest only, N>1 -> process every N uvfits
if [[ -n "$3" && "$3" != "-" ]]; then
   process_all=$3
fi

# typical inttime=0.2831 seconds and number of integrations 8140  -i 0.2831 -n 8140 now for sensitivity we should have 2 timesteps in a single uvfits :
inttime=0.2831 # sensitivity 0.14
if [[ -n "$4" && "$4" != "-" ]]; then
   inttime=$4
fi

n_avg=8140 # sensitivity 4096 or 4070
if [[ -n "$5" && "$5" != "-" ]]; then
   n_avg=$5
fi

station_name=eda2
if [[ -n "$6" && "$6" != "-" ]]; then
   station_name=$6
fi
station_name_upper=`echo $station_name | awk '{print toupper($1);}'`

use_full_files=0
if [[ -n "$7" && "$7" != "-" ]]; then
   use_full_files=$7
fi

# imsize=180 # 180 at <= 160 MHz and 360 at > 160 MHz is ok
imsize=`echo $ch_num | awk '{freq_mhz=$1*(400.00/512.00);D_m=35;pi=3.1415;n_pix_f=(freq_mhz/100.00)*D_m*pi;n_pix_int=int(n_pix_f/10.00);print n_pix_int*10+10;;}'`
#if [[ $ch_num -gt 204 ]]; then  
#   imsize=360
#else
#   if [[ $ch_num -lt 141 ]]; then
#      imsize=120
#      if [[ $ch_num -lt 80 ]]; then
#         echo "freq_ch = $ch -> imsize=50"
#         imsize=60
#      fi
#   fi
#fi
if [[ -n "$8" && "$8" != "-" ]]; then
   imsize=$8
fi

convert_options=""
if [[ -n "$9" && "$9" != "-" ]]; then
   convert_options="$9"
fi

movie_png_rate=1 # every fits file is converted to png and movie
if [[ -n "${10}" && "${10}" != "-" ]]; then
   movie_png_rate=${10}
fi

reprocess_all=0
if [[ -n "${11}" && "${11}" != "-" ]]; then
   reprocess_all=${11}
fi

publish=1
if [[ -n "${12}" && "${12}" != "-" ]]; then
   publish=${12}
fi

copy_calibration=1
if [[ -n "${13}" && "${13}" != "-" ]]; then
   copy_calibration=${13}
fi

update_calibration=1
if [[ -n "${14}" && "${14}" != "-" ]]; then
   update_calibration=${14}
fi

max_calibration_age_in_seconds=43200 # 43200 changed to 10min just for testing !
if [[ -n "${15}" && "${15}" != "-" ]]; then
   max_calibration_age_in_seconds=${15}
fi


echo "##################################"
echo "PARAMETERS:"
echo "##################################"
echo "ch      = $ch (as number = $ch_num)"
echo "imsize  = $imsize"
echo "publish = $publish"
echo "copy_calibration = $copy_calibration"
echo "update_calibration = $update_calibration"
echo "max_calibration_age_in_seconds = $max_calibration_age_in_seconds"
echo "##################################"


export PATH=~/Software/eda2tv/:$PATH

mkdir -p merged/

if [[ $copy_calibration -gt 0 ]]; then
   if [[ -d merged/chan_${ch}_XX.uv && -d merged/chan_${ch}_YY.uv ]]; then
      echo "OK : XX and YY calibration files merged/chan_${ch}_XX.uv and merged/chan_${ch}_YY.uv exist -> nothing to be done."
   else
      echo "WARNING : calibration files not provided -> using defaults, which might be incorrect (flux scale for example)"
   
      if [[ ! -d merged/chan_${ch}.uv ]]; then
         mkdir -p merged/calibration/
         echo "cp -a /data/real_time_calibration/last_calibration/chan_${ch}_??.uv merged/"
         cp -a /data/real_time_calibration/last_calibration/chan_${ch}_??.uv merged/
         last_cal_path=`cat /data/real_time_calibration/last_calibration/last_cal_info.txt`
         utc=`basename $last_cal_path`
         dtm_utc=`echo ${utc} | awk '{print substr($1,1,4)"-"substr($1,6,2)"-"substr($1,9,2)" "substr($1,12,2)":"substr($1,15,2)":00";}'`
         # WARNING : directory name is LOCAL (AWST) time -> not -u in date command below, but it can be added if directory is changed to UTC:
         ux=`date -d "${dtm_utc}" +%s`
         echo "INFO : setting last calibration unixtime to $ux -> merged/calibration/last_calibration.txt"
         echo $ux > merged/calibration/last_calibration.txt
      
         echo "INFO : new version only copying _XX.uv and _YY.uv cal. solutions"
      else
         echo "Calibration file merged/chan_${ch}.uv already exists -> no need to copy"
      fi
   fi
else 
   echo "WARNING : copying of calibration from /data/real_time_calibration/last_calibration/ is not required"
fi

if [[ $publish -gt 0 ]]; then
   # prepare html 
   echo "cp ~/Software/eda2tv/sky.template merged/sky.html"
   cp ~/Software/eda2tv/sky.template merged/sky.html
   echo "sed -i 's/FREQ_CHANNEL/${ch}/g' merged/sky.html" > sed!
   echo "sed -i 's/FREQ_VALUE_MHZ/${freq_mhz}/g' merged/sky.html" >> sed!
   echo "sed -i 's/STATION_NAME/${station_name_upper}/g' merged/sky.html" >> sed!
   chmod +x sed!
   ./sed!

   echo "ssh aavs1-server \"mkdir -p /exports/eda/${station_name}/tv/\""
   ssh aavs1-server "mkdir -p /exports/eda/${station_name}/tv/"

   echo "scp merged/sky.html aavs1-server:/exports/eda/${station_name}/tv/"
   scp merged/sky.html aavs1-server:/exports/eda/${station_name}/tv/
else
   echo "WARNING : publishing of html and images on WWW server is not required"
fi   

while [ 1 ];
do
   echo
   date
   
   echo "eda2tv_convert.sh $ch $voltages $process_all $inttime $n_avg $station_name $use_full_files ${imsize} \"${convert_options}\" ${movie_png_rate} ${reprocess_all} ${publish} - $update_calibration $max_calibration_age_in_seconds"
   eda2tv_convert.sh $ch $voltages $process_all $inttime $n_avg $station_name $use_full_files ${imsize} "${convert_options}" ${movie_png_rate} ${reprocess_all} ${publish} - $update_calibration $max_calibration_age_in_seconds
   
   # only first iteration is requested to re-process old data (for example to re-run the pipeline off-line)
   # then set flag to 0
   reprocess_all=0
   
   sleep 30
done
