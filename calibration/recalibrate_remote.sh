#!/bin/bash

# /media/msok/0754e982-0adb-4e33-80cc-f81dda1580c8/aavs2/data/real_time_calibration

# Eda2 : 2020_04_28-12:39

# cal_timestamp_eda2=2020_04_28-12:39
cal_timestamp_eda2=""
if [[ -n "$1" && "$1" != "-" ]]; then
   cal_timestamp_eda2="$1"
fi

# cal_timestamp_aavs2=2020_04_28-12:48
cal_timestamp_aavs2=""
if [[ -n "$2" && "$2" != "-" ]]; then
   cal_timestamp_aavs2="$2"
fi

basedir=/media/msok/0754e982-0adb-4e33-80cc-f81dda1580c8/
if [[ -n "$3" && "$3" != "-" ]]; then
   basedir="$3"
fi

# eda2 :
if [[ -n "$cal_timestamp_eda2" ]]; then
   echo "DEBUG : re-calibrating EDA2 station"
   
   station=eda2
   cd ${basedir}/${station}/data/real_time_calibration
   rsync --exclude 'cal.out' --exclude 'NoSunBeamCorr' -avP ${station}:/data/real_time_calibration/${cal_timestamp_eda2} .
   cd ${cal_timestamp_eda2}
   echo "~/github/station_beam/beam_correct_latest_cal.sh ${station} ${cal_timestamp_eda2}"
   ~/github/station_beam/beam_correct_latest_cal.sh ${station} ${cal_timestamp_eda2}
else
  echo "DEBUG : re-calibration of EDA2 station is not required"
fi

if [[ -n "$cal_timestamp_aavs2" ]]; then
   echo "DEBUG : re-calibrating AAVS2 station"
   
   # aavs2 :
   station=aavs2
   cd ${basedir}/${station}/data/real_time_calibration
   rsync -avP --exclude 'cal.out' --exclude 'NoSunBeamCorr' ${station}:/data/real_time_calibration/${cal_timestamp_aavs2} .
   cd ${cal_timestamp_aavs2}
   echo "~/github/station_beam/beam_correct_latest_cal.sh ${station} ${cal_timestamp_aavs2}"
   ~/github/station_beam/beam_correct_latest_cal.sh ${station} ${cal_timestamp_aavs2}
else
   echo "DEBUG : re-calibration of AAVS2 station is not required"
fi

