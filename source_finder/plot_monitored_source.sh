#!/bin/bash

infile=sgr1935+2154.txt
if [[ -n "$1" && "$1" != "-" ]]; then
   infile=$1
fi

mkdir -p images/
root -l -b -q "plot_flux_vs_time.C(\"sgr1935+2154.txt\")"

awk '{if($1!="#"){print $1" "$2/$7;}}' sgr1935+2154.txt > sgr1935+2154_SNR.txt
root -l -b -q "plot_snr_vs_time.C(\"sgr1935+2154_SNR.txt\")"

awk '{if($1!="#"){print $1" "$4;}}' sgr1935+2154.txt > sgr1935+2154_diff_vs_time.txt
root -l -b -q "plot_fluxdiff_vs_time.C(\"sgr1935+2154_diff_vs_time.txt\")"

awk '{if($1!="#"){print $1" "$4/$7;}}' sgr1935+2154.txt > sgr1935+2154_diffSNR_vs_time.txt
root -l -b -q "plot_snrdiff_vs_time.C(\"sgr1935+2154_diffSNR_vs_time.txt\")"


