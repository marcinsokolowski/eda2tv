#!/bin/bash

export PATH=~/Software/eda2tv/source_finder/:$PATH

while [ 1 ];
do 
   echo "monitor_sources.sh"
   monitor_sources.sh 

   echo "sleep 60"   
   sleep 60
done
   