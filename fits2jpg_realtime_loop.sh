#!/bin/bash

sleep_time=1
station_name=eda2

# copy :
ssh aavs1-server "mkdir -p /exports/eda/${station_name}/tv/realtime"

while [ 1 ];
do
   echo
   date
   echo "fits2jpg_realtime.sh"
   fits2jpg_realtime.sh
   date


   # copy to WWW page:
   echo "rsync -avP ~/Software/eda2tv/sky_realtime.html aavs1-server:/exports/eda/${station_name}/tv/realtime/"
   rsync -avP ~/Software/eda2tv/sky_realtime.html aavs1-server:/exports/eda/${station_name}/tv/realtime/

   last=`ls images/*png | tail -1`
   echo "rsync -avP $last aavs1-server:/exports/eda/${station_name}/tv/realtime/sky.png"
   rsync -avP $last aavs1-server:/exports/eda/${station_name}/tv/realtime/sky.png
   
   echo "sleep $sleep_time"
   sleep $sleep_time
done
