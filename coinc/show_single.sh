#!/bin/bash

# showing coincindence event in ds9 (from both stations)

wait_for_keypress () {
   echo "Press any key to continue"
   while [ true ] ; do
      read -t 100000 -n 1
      if [ $? = 0 ] ; then
        break
      else
        echo "waiting for the keypress"
      fi
   done
}   

function clean_stdin()
{
    while read -e -t 0.1; do : ; done
}


# wait_for_keypress 1000

event_file=chan_204_20220913T102624_I_diff_cand.txt
if [[ -n "$1" && "$1" != "-" ]]; then
   event_file=$1
fi

fits_file=${event_file%%_cand.txt}.fits
reg_file=${event_file%%txt}reg

echo "############################################################"
echo "PARAMETERS:"
echo "############################################################"
echo "event_file = $event_file ($fits_file , $reg_file)"
echo "############################################################"

i=0
while read line # example 
do
   first=`echo $line | awk '{print $1;}'`
   if [[ $first != "#" ]]; then
      echo "ds9 -geometry 2000x1200  -scale zscale ${fits_file} -regions load ${reg_file} -zoom to fit -grid yes -grid type publication -grid skyformat degrees -grid labels def1 no  &"
      ds9 -geometry 2000x1200 -scale zscale ${fits_file} -regions load ${reg_file} -zoom to fit  -grid yes -grid type publication -grid skyformat degrees -grid labels def1 no  &
   
      # FITSNAME X Y FLUX[Jy] SNR ThreshInSigma RMS RA[deg] DEC[deg] AZIM[deg] ELEV[deg] UXTIME IMAGE_MIN IMAGE_MAX
      # chan_204_20220913T102624_I_diff.fits 67 69 15.95 5.51 5.00 2.90 287.987605 -40.414884 131.797881 66.761804 1663064784.00 -15.9033 18.9519
      fits_file2=`echo $line | awk '{print $1;}'`
      x=`echo $line | awk '{print $2;}'`
      y=`echo $line | awk '{print $3;}'`
      flux=`echo $line | awk '{print $4;}'`
      snr=`echo $line | awk '{print $5;}'`
      thresh_in_sigma=`echo $line | awk '{print $6;}'`
      rms=`echo $line | awk '{print $7;}'`
      ra=`echo $line | awk '{print $8;}'`
      dec=`echo $line | awk '{print $9;}'`
      azim=`echo $line | awk '{print $10;}'`
      elev=`echo $line | awk '{print $11;}'`
      uxtime=`echo $line | awk '{print $12;}'`
      image_min_flux=`echo $line | awk '{print $13;}'`
      image_max_flux=`echo $line | awk '{print $14;}'`
   
      echo "-----------------------------------------------------------------------------------------"
      echo "Showing event $i from file $event_file"
      echo "-----------------------------------------------------------------------------------------"
      echo "FITS FILE = $fits_file2 ($fits_file)"
      echo "(X,Y)     = ($x,$y)"
      echo "(RA,DEC)  = ($ra,$dec) [deg]"
      echo "(AZIM,ELEV) = ($azim,$elev) [deg]"
      echo "UXTIME    = $uxtime"
      echo "flux      = $flux [Jy]"
      echo "Image min/max flux = $image_min_flux / $image_max_flux"
      echo "SNR       = $snr (threshold = $thresh_in_sigma)"
      echo "RMS of noise = $rms"
      echo "-----------------------------------------------------------------------------------------"

      # !!!??? does not work - probably because of while with read there !!!???
      # wait_for_keypress 
      # read -p "Press any key to continue... " -n 1 -s -t 100000 -r stdin
      sleep 1
   else
      echo "DEBUG : comment skipped"
   fi

   i=$(($i+1))
   
   sleep 1
done < $event_file
