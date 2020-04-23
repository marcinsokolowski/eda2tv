#!/bin/bash

listfile="uvfits_list"
if [[ -n "$1" && "$1" != "-" ]]; then
  listfile=$1
fi

cal=chan_204_20191228T052443
if [[ -n "$2" && "$2" != "-" ]]; then
   cal=$2
fi

imsize=180 # 128 or 256 
if [[ -n "$3" && "$3" != "-" ]]; then
   imsize=$3
fi

robust=-0.5
if [[ -n "$4" && "$4" != "-" ]]; then
   robust=$4
fi

frb_x=99
frb_y=86


average_images_path=`which average_images.py`
print_path=`which print_image_flux_single.py`

rm -f values.txt values_XX.txt values_YY.txt


for uvfits in `cat $listfile`
do
   uvfits_base=${uvfits%%.uvfits}

   if [[ ! -s ${uvfits_base}_XX.fits ]]; then
      echo "miriad_applycal_and_image.sh ${uvfits_base} ${cal} ${imsize} ${robust}"
      miriad_applycal_and_image.sh ${uvfits_base} ${cal} ${imsize} ${robust}
      
#      ls ${uvfits_base}_XX.fits ${uvfits_base}_YY.fits > ${uvfits_base}.list 
      
#      echo "python $average_images_path ${uvfits_base}.list ${uvfits_base}_I.fits 0 0 -10000 +10000"
#      python $average_images_path ${uvfits_base}.list ${uvfits_base}_I.fits 0 0 -10000 +10000 
      
#      echo "python $print_path ${uvfits_base}_I.fits $frb_x $frb_y >> values_I.txt"
#      python $print_path ${uvfits_base}_I.fits $frb_x $frb_y >> values_I.txt
      
#      echo "python $print_path ${uvfits_base}_XX.fits $frb_x $frb_y >> values_XX.txt"
#      python $print_path ${uvfits_base}_XX.fits $frb_x $frb_y >> values_XX.txt
      
#      echo "python $print_path ${uvfits_base}_YY.fits $frb_x $frb_y >> values_YY.txt"
#      python $print_path ${uvfits_base}_YY.fits $frb_x $frb_y >> values_YY.txt
      
      
   else
      echo "$uvfits already processed -> skipped"
   fi
done

# export PATH="/opt/caastro/ext/anaconda/bin:$PATH"
# sd9all! 1 - - "chan_204*XX.fits" - - "images_XX/"
# sd9all! 1 - - "chan_204*YY.fits" - - "images_YY/"
# sd9all! 1 - - "chan_204*I.fits"  - - "images_I/"


# ls chan_204*_I.fits > fits_list_I
# diff_images.sh fits_list_I I

# ls chan_204*_XX.fits > fits_list_XX
# diff_images.sh fits_list_XX XX

# ls chan_204*_YY.fits > fits_list_YY
# diff_images.sh fits_list_YY YY

# path_rms=`which rms.py`
# echo "python $path_rms diff_fits_list_I -x ${frb_x} -y ${frb_y} --radius=5 > rms_x${frb_x}_y${frb_y}_radius5.txt"
# python $path_rms diff_fits_list_I -x ${frb_x} -y ${frb_y} --radius=5 > rms_x${frb_x}_y${frb_y}_radius5.txt
