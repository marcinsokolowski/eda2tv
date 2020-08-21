#!/bin/bash

logfile="coinc_eda2_aavs2.txt"

awk -v prev=-1 '{if($1!="#" && $13==prev){print $0;}prev=$13;}' $logfile  |wc

for uxtime in `awk -v prev=-1 '{if($1!="#" && $13==prev){print $13;}prev=$13;}' $logfile`
do
   count=`awk -v count=0 -v uxtime=${uxtime} '{if($1!="#" && $13==uxtime){count++;}}END{print count;}' $logfile`
   echo "$uxtime : $count"
done
