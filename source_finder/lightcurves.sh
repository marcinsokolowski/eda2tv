#!/bin/bash

ra=331.87375
if [[ -n "$1" && "$1" != "-" ]]; then
  ra=$1
fi

dec=-80.10958333
if [[ -n "$2" && "$2" != "-" ]]; then
  dec=$2
fi

# 10:15:38 , 7:18:39 
# name=cand1015+07 # echo 153.23342 -7.9 | awk '{h=int($1/15.00);m=(($1/15.00)-h)*60.00;dec_deg=int($2);printf("%d%d%03d\n",h,m,dec_deg);}'
name=`echo "$ra $dec" | awk '{h=int($1/15.00);m=(($1/15.00)-h)*60.00;dec_deg=int($2);printf("cand%d%d%03d\n",h,m,dec_deg);}'`
if [[ -n "$3" && "$3" != "-" ]]; then
   name=$3
fi

beam_x=1.00
if [[ -n "$4" && "$4" != "-" ]]; then
   beam_x=$4
fi

beam_y=1.00
if [[ -n "$5" && "$5" != "-" ]]; then
   beam_y=$5
fi

options=""
if [[ -n "$6" && "$6" != "-" ]]; then
   options=$6
fi

inttime_ms=2000

min_elevation=15
radius_deg=3

export PATH=~/Software/eda2tv/source_finder/:$PATH

path=`which dump_pixel_radec.py`

mkdir -p images/

# FILE FIT_SIGMA FIT_MEAN FIT_NORM MEAN RMS
# FRB200914_EDA2_I_diff.txt 3.80430486 0.24747998 15.95698007 0.05316678 3.91609535 0

rm -f ${name}_final_results.txt 

rms_xx=-1000
rms_yy=-1000
rms_i=-1000

for postfix in `echo "I I_diff XX XX_diff YY YY_diff"`
do
   ls *_${postfix}.fits > fits_list_${postfix}_tmp
   
   name2=${name}_${postfix}
   
   echo "python $path fits_list_${postfix}_tmp --ra=${ra} --dec=${dec} --calc_rms --outfile=${name2}.txt --min_elevation=${min_elevation} --radius=${radius_deg} --last_processed_filestamp=${name2}.last_processed_file ${options}"
   python $path fits_list_${postfix}_tmp --ra=${ra} --dec=${dec} --calc_rms --outfile=${name2}.txt --min_elevation=${min_elevation} --radius=${radius_deg} --last_processed_filestamp=${name2}.last_processed_file ${options}

   root -b -q -l "plot_flux_vs_time.C(\"${name2}.txt\")"
   root -b -q -l "histofile.C(\"${name2}.txt\",1,1)"
   
   rms=`grep $name2 sigma.txt | tail -1 | awk '{print $6}'`
   sigma_fit=`grep $name2 sigma.txt | tail -1 | awk '{print $2}'`
   
   is_diff=`echo $postfix | awk '{if(index($1,"_diff")>0){print 1;}else{print 0;}}'`
   
   if [[ $is_diff -gt 0 ]]; then
      rms_normal=`echo $rms | awk '{printf("%.4f",($1/sqrt(2.00)));}'`
      sigma_fit_normal=`echo $sigma_fit | awk '{printf("%.4f",($1/sqrt(2.00)));}'`
      echo "RESULT diff : $postfix rms = $rms , sigma_fit = $sigma_fit -> RMS on normal = $rms_normal , sigma_fit_normal = $sigma_fit_normal"
      echo "RESULT diff : $postfix rms = $rms , sigma_fit = $sigma_fit -> RMS on normal = $rms_normal , sigma_fit_normal = $sigma_fit_normal" >> ${name}_final_results.txt
      
      if [[ $postfix == "XX_diff" ]]; then
         rms_xx=$sigma_fit_normal
      fi
      if [[ $postfix == "YY_diff" ]]; then
         rms_yy=$sigma_fit_normal
      fi
      if [[ $postfix == "I_diff" ]]; then
         rms_i=$sigma_fit_normal
      fi
   else
      echo "RESULT (not diff) : $postfix rms = $rms , sigma_fit = $sigma_fit"
      echo "RESULT (not diff) : $postfix rms = $rms , sigma_fit = $sigma_fit" >> ${name}_final_results.txt
   fi
done

rms_i_calc_beam=`echo "$rms_xx $beam_x $rms_yy $beam_y" | awk '{brx=$1/$2;bry=$3/$4;rms_i=0.5*sqrt(brx*brx + bry*bry);printf("%.4f",rms_i);}'`
rms_fluence_calc_beam=`echo "$rms_i_calc_beam $inttime_ms" | awk '{printf("%.2f",($1*$2));}'`

rms_i_calc_nobeam=`echo "$rms_xx 1.00 $rms_yy 1.00" | awk '{brx=$1/$2;bry=$3/$4;rms_i=0.5*sqrt(brx*brx + bry*bry);printf("%.4f",rms_i);}'`

echo "-----------------------------------------"
echo "FINAL RESULTS :"
echo "-----------------------------------------"
cat ${name}_final_results.txt 
echo "-------------------"
echo "Summary :"
echo "-------------------"
echo "beam_x = $beam_x , rms_xx  = $rms_xx"
echo "beam_y = $beam_y , rms_yy  = $rms_yy"
echo "rms_i (data) = $rms_i ( calc no beam = $rms_i_calc_nobeam )" 
echo "rms_i (calc beam) = $rms_i_calc_beam"
echo "FINAL Fluence limit = $rms_fluence_calc_beam Jy ms" 
echo "-----------------------------------------"
