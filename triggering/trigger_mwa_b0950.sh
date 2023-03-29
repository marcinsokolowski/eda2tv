#!/bin/bash

min_count_spikes=20
sleep_time=300

ra_deg=148.28875 
dec_deg=7.92638889
name="B0950_eda2"

trigger_count=0
max_trigger_count=3

while [ 1 ];
do
   echo 
   echo "----------------------------------"
   date
   echo "count_spikes.sh > count_spikes.out 2>&1"
   count_spikes.sh > count_spikes.out 2>&1

   uxtime=`date +%s`
   uxtime_hour_ago=$(($uxtime-3600))

   cd lc_filtered
   count=`cat B0950+08_diff_thresh10sigma.txt | awk -v ux_start=${uxtime_hour_ago} -v ux_end=${uxtime} '{if($1!="#" && $1>=ux_start && $1<=ux_end){print $0;}}' | wc -l`
   
   echo "   Number of spikes in uxtime range $uxtime_hour_ago - $uxtime is $count vs. threshold $min_count_spikes"
   
   if [[ $count -gt $min_count_spikes ]]; then
      echo "TRIGGERING : count spikes = $count > threshold = $min_count_spikes -> triggering"
      
      # name="B0950_eda2_$uxtime"
      # url=""
      # echo "wget $url"
      # wget $url      
      
      if [[ $trigger_count -gt $max_trigger_count ]]; then
         echo "   DEBUG : trigger_count > $trigger_count -> stopping triggering (ignored in pretend=true mode)"
         # exit
      else
         echo "   DEBUG : trigger_count = $trigger_count -> continuing"
      fi      
      
      trigger_count=$(($trigger_count+1))
   else
      echo "DEBUG : count spikes = $count below threshold = $min_count_spikes -> no action"
   fi
         
   cd ..   
   
   echo "sleep $sleep_time"
   sleep $sleep_time
done


