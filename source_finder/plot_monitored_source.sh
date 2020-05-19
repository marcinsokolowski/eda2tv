#!/bin/bash

infile=sgr1935+2154.txt
if [[ -n "$1" && "$1" != "-" ]]; then
   infile=$1
fi

root_options="-l -b -q"
if [[ -n "$2" && "$2" != "-" ]]; then
   root_options="$2"
fi

mkdir -p images/
root ${root_options} "plot_flux_vs_time.C(\"sgr1935+2154.txt\")"

awk '{if($1!="#"){print $1" "$2/$7;}}' sgr1935+2154.txt > sgr1935+2154_SNR.txt
root ${root_options} "plot_snr_vs_time.C(\"sgr1935+2154_SNR.txt\")"

awk '{if($1!="#"){print $1" "$4;}}' sgr1935+2154.txt > sgr1935+2154_diff_vs_time.txt
root ${root_options} "plot_fluxdiff_vs_time.C(\"sgr1935+2154_diff_vs_time.txt\")"

awk '{if($1!="#"){print $1" "$4/$7;}}' sgr1935+2154.txt > sgr1935+2154_diffSNR_vs_time.txt
root ${root_options} "plot_snrdiff_vs_time.C(\"sgr1935+2154_diffSNR_vs_time.txt\")"


