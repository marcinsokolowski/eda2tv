#!/bin/bash

start_ux=1599609600
if [[ -n "$1" && "$1" != "-" ]]; then
   start_ux=$1  
fi

location=cen
if [[ -n "$2" && "$2" != "-" ]]; then
   location=$2
fi
# while [[ $ux -le 1599652800 ]];
# do

min_elev=0 # 45 
if [[ -n "$3" && "$3" != "-" ]]; then
   min_elev=$3
fi

mkdir -p minElev${min_elev}deg
cd minElev${min_elev}deg/

tle_file=
if [[ -n "$4" && "$4" != "-" ]]; then
   tle_file=$4
fi

interval=45200
if [[ -n "$5" && "$5" != "-" ]]; then
   interval=$5
fi

step=1
if [[ -n "$6" && "$6" != "-" ]]; then
   step=$6
fi

if [[ ! -n ${tle_file} ]]; then
   echo "WARNING : TLE file not specified -> will try using the most up to date"
  
   # /home/msok/bighorns/data/TLE/${dt}/satelitesdb.tle
   tle_path=/home/msok/bighorns/data/TLE/
  
   ux=$start_ux
   found=0
   max_iter=5
   while [[ $found -le 0 && $iter -lt $max_iter ]];
   do
      dt=`date -d "1970-01-01 UTC $ux seconds" +"%Y%m%d"`
      tle_file_test=${tle_path}/${dt}/satelitesdb.tle

      echo "DEBUG : $ux -> $dt : checking file ${tle_file_test} ..."
      
      if [[ -s ${tle_file_test} ]]; then
         echo "DEBUG : found ${tle_file_test} -> copying ..."

         echo "cp ${tle_file_test} ."
         cp ${tle_file_test} .
         
         echo "Using local TLE file satelitesdb.tle"
         tle_file=satelitesdb.tle
         
         found=1
      else
         echo "   WARNING : file ${tle_file_test} does not exist, trying 1 day earlier ..."
      fi
      
      ux=$(($ux-86400))   
      iter=$(($iter+1))
   done

fi

sattest_path="/opt/pi/dev/pisys/daq/src/ccd/TESTY/sattest/sattest"

if [[ ! -s ${sattest_path} ]]; then
   echo "ERROR : sattest program is not installed -> cannot continue (ask MS for help)"
   exit -1
fi

qth_file=${location}.qth
if [[ ! -s ${location}.qth ]]; then
   if [[ -s ~/github/eda2tv/tle/${location}.qth ]]; then
      echo "cp ~/github/eda2tv/tle/${location}.qth ."
      cp ~/github/eda2tv/tle/${location}.qth .           
   else
      echo "ERROR : files not found :  ${location}.qth nor ~/github/eda2tv/tle/${location}.qth -> cannot continue"
      exit -2
   fi
fi

echo "###########################################################"
echo "PARAMETERS :"
echo "###########################################################"
echo "start_ux = $start_ux -> dt = $dt"
echo "location = $location -> qth_file = ${qth_file}"
echo "min_elev = $min_elev [deg]"
echo "tle_file = $tle_file"
echo "interval = $interval"
echo "step     = $step"
echo "###########################################################"

ux=${start_ux}
end_ux=$(($start_ux+$interval))

while [[ $ux -le $end_ux ]];
do
   echo "${sattest_path} $ux -tle=$tle_file -all -mwa -qth=${qth_file} -outregfile=minelev${min_elev}_${ux}.reg  -outfile=${ux}.txt -print_header -min_elevation=${min_elev} -interval=1 > ${ux}.out 2>&1"
   ${sattest_path} $ux -tle=$tle_file -all -mwa -qth=${qth_file} -outregfile=minelev${min_elev}_${ux}.reg  -outfile=${ux}.txt -print_header -min_elevation=${min_elev} -interval=1 > ${ux}.out 2>&1
   
   ux=$(($ux+$step))
done
   
   
echo "Done at:"   
date
pwd
