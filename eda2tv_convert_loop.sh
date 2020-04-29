#!/bin/bash

ch=204
if [[ -n "$1" && "$1" != "-" ]]; then
   ch=$1
fi
freq_mhz=`echo $ch | awk '{printf("%.4f",$1*(400.00/512.00));}'`

voltages=1
if [[ -n "$2" && "$2" != "-" ]]; then
   voltages=$2
fi

process_all=0
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

imsize=180 # 180 at <= 160 MHz and 360 at > 160 MHz is ok
if [[ $freq_ch -gt 204 ]]; then
   imsize=360
else
   if [[ $freq_ch -lt 141 ]]; then
      imsize=120
      if [[ $freq_ch -lt 80 ]]; then
         imsize=60
      fi
   fi
fi
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

export PATH=~/Software/eda2tv/:$PATH

mkdir -p merged/
echo "cp -a /data/real_time_calibration/last_calibration/chan_${ch}.uv merged/"
cp -a /data/real_time_calibration/last_calibration/chan_${ch}.uv merged/

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

while [ 1 ];
do
   echo
   date
   
   echo "eda2tv_convert.sh $ch $voltages $process_all $inttime $n_avg $station_name $use_full_files ${imsize} \"${convert_options}\" ${movie_png_rate} ${reprocess_all}"
   eda2tv_convert.sh $ch $voltages $process_all $inttime $n_avg $station_name $use_full_files ${imsize} "${convert_options}" ${movie_png_rate} ${reprocess_all}
   
   # only first iteration is requested to re-process old data (for example to re-run the pipeline off-line)
   # then set flag to 0
   reprocess_all=0
   
   sleep 30
done
