#!/bin/bash

hdf5_file=correlation_burst_204_20211116_04114_56.hdf5
if [[ -n "$1" && "$1" != "-" ]]; then
   hdf5_file=$1
fi

subdir=merged_current_config
if [[ -n "$2" && "$2" != "-" ]]; then
   subdir=$2
fi
path=`pwd`
mkdir -p ${subdir}
cd ${subdir}

config_file=~/aavs-calibration/config/eda2/instr_config.txt
if [[ -n "$3" && "$3" != "-" ]]; then
   config_file=$3

   echo "cp $config_file ."
   cp $config_file .

   echo "chmod -w instr_config.txt"
   chmod -w instr_config.txt
fi

base_filename=
if [[ -n "$4" && "$4" != "-" ]]; then
   base_filename=$4
fi

station=eda2
if [[ -n "$5" && "$5" != "-" ]]; then
   station=$5
fi

ch=204
if [[ -n "$6" && "$6" != "-" ]]; then
   ch=$6
fi

size=180
if [[ -n "$7" && "$7" != "-" ]]; then
   size=$7
fi


# kdiff3 instr_config.txt ../merged_current_version1/instr_config.txt &
echo "ln -s ${path}/${hdf5_file}"
ln -s ${path}/${hdf5_file}


ls ${hdf5_file} > new_hdf5_list.txt

echo "hdf5_to_uvfits_all.sh -c -l -i 1.98181 -n 1 -d ./ -N -z -a 1 -f ${ch} -L new_hdf5_list.txt -S 0 -s ${station} -a 1"
hdf5_to_uvfits_all.sh -c -l -i 1.98181 -n 1 -d ./ -N -z -a 1 -f ${ch} -L new_hdf5_list.txt -S 0 -s ${station} -a 1

echo "ls ${base_filename}*.uvfits > uvfits_list"
ls ${base_filename}*.uvfits > uvfits_list

echo "miriad_applycal_and_image_list.sh uvfits_list chan_${ch} ${size} - 1"
miriad_applycal_and_image_list.sh uvfits_list chan_${ch} ${size} - 1
