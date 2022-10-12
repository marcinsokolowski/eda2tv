#!/bin/bash

ux_start=1660855800
ux_end=1660857000


ux=${ux_start}
while [[ $ux -le ${ux_end} ]];
do   
   echo "/opt/pi/dev/pisys/daq/src/ccd/TESTY/sattest/sattest $ux -tle=TestDataTLE.txt -all -mwa -qth=mro.qth -outregfile=test.reg -outfile=${ux}.txt -print_header -min_elevation=-1000  -interval=1"
   /opt/pi/dev/pisys/daq/src/ccd/TESTY/sattest/sattest $ux -tle=TestDataTLE.txt -all -mwa -qth=mro.qth -outregfile=test.reg -outfile=${ux}.txt -print_header -min_elevation=-1000  -interval=1 

   ux=$(($ux+1))
done
