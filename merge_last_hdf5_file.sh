#!/bin/bash

n_iterations=-1
if [[ -n "$1" && "$1" != "-" ]]; then
   n_iterations=$1
fi

sleep_time=60
if [[ -n "$2" && "$2" != "-" ]]; then
   sleep_time=$2
fi

do_merge=1
merge_script_path=`which merge_n_hdf5_files.py`
merged_dir="merged/"

echo "Started merge_last_hdf5_file.sh at :"
date

mkdir -p ${merged_dir}


iter=0
while [[ $iter -lt $n_iterations ]];
do
   echo
   echo "New processing loop started at:"
   date
   # read last HDF5 file processed from the file (if exists)
   last_hdf5file=""
   if [[ -s last_hdf5_file.txt ]]; then
      last_hdf5file=`cat last_hdf5_file.txt`
   fi


   # list all collected HDF5 files (tpm-0 only as a "marker")
   ls channel_cont_0_*_*.hdf5 > hdf5_file0_list

   started=1
   if [[ -n $last_hdf5file && -s last_hdf5_file.txt ]]; then
      started=0
   fi
   echo "started = $started"
   
#   awk -v started=${started} -v last_hdf5file=$last_hdf5file '{if(started>0){print $0;}else{if($1==last_hdf5file){started=1;}}}' hdf5_file0_list > new_hdf5_files_to_process
 
   # prepare the list of new _0_ hdf5 files to be converted by the only GOOD WAY OF DOING IT - means checking if the merged file exists already or not !
   rm -f new_hdf5_files_to_process
   for hdf5_file in `cat hdf5_file0_list`
   do
      merged_hdf5_file=`echo $hdf5_file | awk '{gsub("channel_cont_0_","channel_cont_");print $1;}'`
      if [[ ! -s merged/${merged_hdf5_file} ]]; then
         echo "$hdf5_file" >> new_hdf5_files_to_process
      fi
   done
   
   # do merging of all files in new_hdf5_files_to_process
   for hdf5_file in `cat new_hdf5_files_to_process`
   do
      echo "Processing file $hdf5_file at "
      date

      if [[ $do_merge -gt 0 ]]; then
         echo "python $merge_script_path ${hdf5_file} 16 - --outdir=${merged_dir}"      
         python $merge_script_path ${hdf5_file} 16 - --outdir=${merged_dir}
      else
         echo "Merging is not required"
      fi
   done
   
   # update last processed file :
   tail -1 new_hdf5_files_to_process > last_hdf5_file.txt
   
   if [[ $n_iterations -gt 1 && $sleep_time -gt 0 ]]; then
      echo "sleep $sleep_time"
      sleep $sleep_time
   else
      echo "sleep skipped"
   fi
   
   iter=$(($iter+1))
done
