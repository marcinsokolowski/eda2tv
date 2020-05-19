#!/bin/bash

# export PATH=$PATH:/opt/install/mwa/Aegean-master/
# export PATH=/opt/install/mwa/Aegean-master_xy:$PATH

fits=1086548440145-145_1086535240_full_EE.ms_briggs-1_TH30mJy_CF10_hogbom__I_2arcmin_1000px_UV0~1000000lambda_beam_corrected.fits
if [[ -n "$1" && "$1" != "-" ]]; then
   fits=$1
fi


noise=${fits%%.fits}_rms.fits
bkg=${fits%%.fits}_bkg.fits
cat=${fits%%fits}cat
reg=${fits%%fits}reg
txt=${fits%%fits}txt
xml=${fits%%fits}xml

echo "BANE.py ${fits}"
BANE.py ${fits}

# echo "aegean.py ${fits}  --noise=${noise} --background=${bkg}  --out=${cat} --telescope=MWA --psf=psf.fits"
# aegean.py ${fits}  --noise=${noise} --background=${bkg}  --out=${cat} --telescope=MWA --psf=psf.fits
echo "aegean.py ${fits}  --noise=${noise} --background=${bkg}  --out=${cat} --telescope=MWA --table=${xml}"
aegean.py ${fits}  --noise=${noise} --background=${bkg}  --out=${cat} --telescope=MWA --table=${xml}

awk '{first=substr($1,1,1);if(first!="#"){print "circle "$22" "$21" 5";}}' ${cat} > ${reg}
awk '{first=substr($1,1,1);if(first!="#"){print $21" "$22" "$6" "$8" "$10;}}' ${cat} > ${txt}

