#!/bin/bash

rsync -avP eda2:/data/2024_07_29_ch294_corr/merged/*_I_diff_cand.??? .

mkdir -p images/
for regfile in `ls *_I_diff_cand.reg`
do
   fits=${regfile%%_cand.reg}.fits
   pngfile=${regfile%%reg}png
   txtfile=${regfile%%reg}txt

   echo "rsync -avP eda2:/data/2024_07_29_ch294_corr/merged/${fits} ."
   rsync -avP eda2:/data/2024_07_29_ch294_corr/merged/${fits} .

   echo "Candidate:"
   cat $txtfile

   if [[ -s images/${pngfile} ]]; then
      echo "Already inspected -> skipped"
   else
      echo "ds9 ${fits} -scale zscale -geometry 2250x1500  -zoom 0.25 -zoom to fit -regions load ${regfile} -saveimage png images/${pngfile}"
      ds9 ${fits} -scale zscale -geometry 2250x1500  -zoom 0.25 -zoom to fit -regions load ${regfile} -saveimage png images/${pngfile}
   fi
done