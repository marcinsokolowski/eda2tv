#!/bin/bash

src=chan_204_20191228T052443
if [[ -n "$1" && "$1" != "-" ]]; then
  src=$1
fi

cal=chan_204_20191228T052443
if [[ -n "$2" && "$2" != "-" ]]; then
   cal=$2
fi

is_cal_xxyy=`echo $cal | awk '{u=toupper($1);is_cal_xxyy=index(u,"_X");if(is_cal_xxyy<=0){is_cal_xxyy=index(u,"_Y");}print is_cal_xxyy;}'`
echo "is_cal_xxyy = $is_cal_xxyy"

imsize=180 # 128 or 256 
if [[ -n "$3" && "$3" != "-" ]]; then
   imsize=$3
fi

robust=-0.5
if [[ -n "$4" && "$4" != "-" ]]; then
   robust=$4
fi


if [[ -d ${src}.uv ]]; then
   echo "UV files ${src}.uv exist -> no need to execute conversion task (.uvfits -> .uv) : fits op=uvin in=${src}.uvfits out=${src}.uv options=compress"
else
   echo "fits op=uvin in=${src}.uvfits out=${src}.uv options=compress"
   fits op=uvin in=${src}.uvfits out=${src}.uv options=compress
fi

# FLAGGING for 2019-12-28 data (EDA2) :
# uvflag flagval=flag vis=${src}.uv select='ant(1,2,3,4,5,6,7,8,9,17,18,19,20,21,22,23,24,31,60,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,125,129,130,131,132,133,134,135,136,137,138,139,140)'
# uvflag flagval=flag vis=${src}.uv select='ant(141,142,143,144,153,154,155,156,157,158,159,160,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,201,202,203,204,205,206,207,208,217,218,219,220,221,222,223,224,230,241,245,249,250,251,252,253,254,255,256)'

# 2019-12-28 AAVS2 :
# uvflag flagval=flag vis=${src}.uv select='ant(1,2,3,4,5,6,7,8,33,34,35,36,37,38,39,40,57,58,59,60,61,62,63,64,117,118,119,120,125,126,127,128,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,201,202,203,204,205,206,207)'
# uvflag flagval=flag vis=${src}.uv select='ant(208,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,241,242,243,244,245,246,247,248)'

puthd in=${src}.uv/jyperk value=2000.0
puthd in=${src}.uv/systemp value=200.0

cnt_xxyy=`ls -d ${src}_XX.uv ${src}_YY.uv | wc -l`

if [[ $cnt_xxyy -le 0 ]]; then
   echo "uvcat vis=${src}.uv stokes=xx out=${src}_XX.uv"
   uvcat vis=${src}.uv stokes=xx out=${src}_XX.uv
   
   echo "uvcat vis=${src}.uv stokes=yy out=${src}_YY.uv"
   uvcat vis=${src}.uv stokes=yy out=${src}_YY.uv
fi

# apply calibration in both XX and YY :
echo "gpcopy vis=${cal}_XX.uv out=${src}_XX.uv options=relax"
gpcopy vis=${cal}_XX.uv out=${src}_XX.uv options=relax
   
echo "gpcopy vis=${cal}.uv out=${src}.uv options=relax"
gpcopy vis=${cal}_YY.uv out=${src}_YY.uv options=relax

# images :
rm -f ${src}_XX.map ${src}_XX.beam
echo "invert vis=${src}_XX.uv map=${src}_XX.map imsize=${imsize},${imsize} beam=${src}_XX.beam robust=$robust options=double,mfs stokes=XX select='uvrange(0.0,100000)'"
invert vis=${src}_XX.uv map=${src}_XX.map imsize=${imsize},${imsize} beam=${src}_XX.beam robust=$robust options=double,mfs stokes=XX select='uvrange(0.0,100000)'
echo "fits op=xyout in=${src}_XX.map out=${src}_XX.fits"
fits op=xyout in=${src}_XX.map out=${src}_XX.fits

rm -f ${src}_YY.map ${src}_YY.beam
echo "invert vis=${src}_YY.uv map=${src}_YY.map imsize=${imsize},${imsize} beam=${src}_YY.beam robust=$robust options=double,mfs stokes=YY select='uvrange(0.0,100000)'"
invert vis=${src}_YY.uv map=${src}_YY.map imsize=${imsize},${imsize} beam=${src}_YY.beam robust=$robust options=double,mfs stokes=YY select='uvrange(0.0,100000)'
echo "fits op=xyout in=${src}_YY.map out=${src}_YY.fits"
fits op=xyout in=${src}_YY.map out=${src}_YY.fits

utc=`fitshdr ${src}_XX.fits  | grep DATE-OBS | awk '{gsub("''","",$0);dtm=substr($2,2,19);gsub("T","_",dtm);gsub("-","",dtm);gsub(":","",dtm);print dtm;}'`
echo "utc = $utc"

# ux=`date2date -ut2ux=${utc} | awk '{print $3;}'`
# lst=`ux2sid $ux | awk '{print $8}'`
# echo "ux = $ux -> lst = $lst"

path=`which fixCoordHdr.py`

echo "python $path ${src}_XX.fits"
python $path ${src}_XX.fits

echo "python $path ${src}_YY.fits"
python $path ${src}_YY.fits

fits=${src}_XX.fits
png=${src}_XX.png
outdir="images/"
if [[ ! -s ${outdir}/${png} || $force -gt 0 ]]; then

   echo "python `which remove_2axis_keywords.py` $fits"
   python `which remove_2axis_keywords.py` $fits

   echo "python `which imagefits.py` $fits --outfile $png --outdir ${outdir} --ext=png $options"
   python `which imagefits.py` $fits --outfile $png --outdir ${outdir} --ext=png $options 
else
   echo "Image $png already exists"
fi

