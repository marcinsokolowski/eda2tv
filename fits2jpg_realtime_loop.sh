#!/bin/bash

sleep_time=30

while [ 1 ];
do
   echo
   date
   echo "fits2jpg_realtime.sh"
   fits2jpg_realtime.sh
   date
   
   echo "sleep $sleep_time"
   sleep $sleep_time
done
