#!/bin/bash

infile=sgr1935+2154.txt
if [[ -n "$1" && "$1" != "-" ]]; then
   infile=$1
fi

root_options="-l -b -q"
if [[ -n "$2" && "$2" != "-" ]]; then
   root_options="$2"
fi

snr_file=${infile%%.txt}_SNR.txt
diff_file=${infile%%.txt}_diff_vs_time.txt
diffsnr_file=${infile%%.txt}_diffSNR_vs_time.txt

mkdir -p images/
root ${root_options} "plot_flux_vs_time.C(\"${infile}\")"

awk '{if($1!="#"){print $1" "$2/$7;}}' ${infile} > ${snr_file}
root ${root_options} "plot_snr_vs_time.C(\"${snr_file}\")"

awk '{if($1!="#"){print $1" "$4;}}' ${infile}  > ${diff_file}
root ${root_options} "plot_fluxdiff_vs_time.C(\"${diff_file}\")"

awk '{if($1!="#"){print $1" "$4/$7;}}' ${infile}  > ${diffsnr_file}
root ${root_options} "plot_snrdiff_vs_time.C(\"${diffsnr_file}\")"

root ${root_options} "histofile.C(\"${infile}\",3,1,-50,50)"
