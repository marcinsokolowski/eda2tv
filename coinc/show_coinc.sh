#!/bin/bash

# showing coincindence event in ds9 (from both stations)

evtidx=0
if [[ -n "$1" && "$1" != "-" ]]; then
   evtidx=$1
fi

logfile=coinc_eda2_aavs2.txt
if [[ -n "$2" && "$2" != "-" ]]; then
   logfile=$2
fi

data_dir_low="low/"
if [[ -n "$3" && "$3" != "-" ]]; then
   data_dir_low=$3
fi

data_dir_high="high/"
if [[ -n "$4" && "$4" != "-" ]]; then
   data_dir_high=$4
fi

auto_copy=1
if [[ -n "$5" && "$5" != "-" ]]; then
   auto_copy=$5
fi

low_server=eda2
if [[ -n "$6" && "$6" != "-" ]]; then
   low_server=$6
fi

high_server=aavs2
if [[ -n "$7" && "$7" != "-" ]]; then
   high_server=$7
fi

curr_path=`pwd`
echo "############################################################"
echo "PARAMETERS:"
echo "############################################################"
echo "Auto :"
echo "low_data_dir_local = $data_dir_low"
echo "high_data_dir_local = $data_dir_high"
echo "current_path = $curr_path"
echo "############################################################"



line=`awk -v idx=0 -v evtidx=$evtidx '{if($1!="#"){if(substr(evtidx,1,3)=="EVT"){if($1==evtidx){print $0;}}else{if(idx==evtidx){print $0;}}idx+=1;}}' ${logfile}`

# ANG_DIST[deg] DELAY[sec] FITSFILE_highfreq Flux_high[Jy] SNR_high RA_high[deg] DEC_high[deg] X_high Y_high UXTIME_high FITSFILE_lowfreq Flux_low[Jy] SNR_low RA_low[deg] DEC_low[deg] X_low Y_low UXTIME_low DIST_sun[deg] AZIM_mean[deg] ELEV_mean[deg]
# 0.0685 0.000 chan_204_20200626T184136_I_diff.fits 88.540 6.2 312.571508 5.793536 91.0 134.0 1593196896.0000 chan_204_20200626T184136_I_diff.fits 129.460 7.7 312.569715 5.862060 91.0 131.0 1593196896.0000 133.8 0.76 57.39
fits_high=`echo $line | awk '{print $6;}'`
fits_low=`echo $line | awk '{print $14;}'`

reg_high=${data_dir_high}/${fits_high%%.fits}_cand.reg
reg_low=${data_dir_low}/${fits_low%%.fits}_cand.reg

pwd
echo "DEBUG : loading HIGH-freq. image ${data_dir_high}/${fits_high}"
echo "ds9 -geometry 2000x1200 -scale zscale ${data_dir_high}/${fits_high} -regions load ${reg_high} -zoom to fit -grid yes -grid type publication -grid skyformat degrees -grid labels def1 no  &"
ds9 -geometry 2000x1200 -scale zscale ${data_dir_high}/${fits_high} -regions load ${reg_high} -zoom to fit -grid yes -grid type publication -grid skyformat degrees -grid labels def1 no  &
#   -grid labels fontsize 30 -grid numerics fontsize 30  -grid axes color blue -grid numerics color black -grid format1 d.0 -grid format2 d.0 -grid axes type exterior -grid numerics type exterior \
#   -grid tickmarks color blue -grid tickmarks no -grid border no \
#   -grid numerics gap1 0.5 -grid numerics gap2 -0.5 \
#   -grid labels gap1 -5.5 -grid labels gap2 4 &

pwd
sleep 1

pwd
echo "DEBUG : loading LOW-freq. image ${data_dir_low}/${fits_low}"
echo "ds9 -geometry 2000x1200  -scale zscale ${data_dir_low}/${fits_low} -regions load ${reg_low} -zoom to fit -grid yes -grid type publication -grid skyformat degrees -grid labels def1 no  &"
ds9 -geometry 2000x1200 -scale zscale ${data_dir_low}/${fits_low} -regions load ${reg_low} -zoom to fit  -grid yes -grid type publication -grid skyformat degrees -grid labels def1 no  &
#   -grid labels fontsize 30 -grid numerics fontsize 30  -grid axes color blue -grid numerics color black -grid format1 d.0 -grid format2 d.0 -grid axes type exterior -grid numerics type exterior \
#   -grid tickmarks color blue -grid tickmarks no -grid border no \
#   -grid numerics gap1 0.5 -grid numerics gap2 -0.5 \
#   -grid labels gap1 -5.5 -grid labels gap2 4 &


# EVTNAME ANG_DIST[deg] DELAY[sec] FITSFILE_highfreq Flux_high[Jy] SNR_high RA_high[deg] DEC_high[deg] X_high Y_high UXTIME_high FITSFILE_lowfreq Flux_low[Jy] SNR_low RA_low[deg] DEC_low[deg] X_low Y_low UXTIME_low DIST_sun[deg] AZIM_mean[deg] ELEV_mean[deg] SATINFO SATDIST[arcsec] MEAN_RA[deg] MEAN_DEC[deg]
# EVT00000000 186.894190 -17.963312 0.6490 -1.000 chan_204_20200626T131542_I_diff.fits 0116.500 007.2 0186.87828 -017.63915 143.0 093.0 1593177342.000 chan_204_20200626T131541_I_diff.fits 0111.500 05.7 186.910099 -18.287473 139.0 92.0 1593177341.0000 98.1 272.83 049.01 CZ-3B_DEB 04889.8

name=`echo $line | awk '{print $1;}'`
mean_ra=`echo $line |  awk '{print $2;}'`
mean_dec=`echo $line |  awk '{print $3;}'`
ang_dist=`echo $line | awk '{print $4;}'`
DELAY=`echo $line | awk '{print $5;}'`
FITSFILE_highfreq=`echo $line | awk '{print $6;}'`
Flux_high=`echo $line | awk '{print $7;}'`
SNR_high=`echo $line | awk '{print $8;}'`
RA_high=`echo $line | awk '{print $9;}'`
DEC_high=`echo $line | awk '{print $10;}'`
X_high=`echo $line | awk '{print $11;}'`
Y_high=`echo $line | awk '{print $12;}'`
UXTIME_high=`echo $line | awk '{print $13;}'`
FITSFILE_lowfreq=`echo $line | awk '{print $14;}'`
Flux_low=`echo $line | awk '{print $15;}'`
SNR_low=`echo $line | awk '{print $16;}'`
RA_low=`echo $line | awk '{print $17;}'`
DEC_low=`echo $line | awk '{print $18;}'`
X_low=`echo $line | awk '{print $19;}'`
Y_low=`echo $line | awk '{print $20;}'`
UXTIME_low=`echo $line | awk '{print $21;}'`
DIST_sun=`echo $line | awk '{print $22;}'`
AZIM_mean=`echo $line | awk '{print $23;}'`
ELEV_mean=`echo $line | awk '{print $24;}'`
SATINFO=`echo $line |  awk '{print $25;}'`
SATDIST=`echo $line |  awk '{print $26;}'`
SATDIST_deg=`echo $line |  awk '{print $26/3600.00;}'`

echo "-----------------------------------------------------------------------------------------"
echo "Showing coincidence event $evtidx"
echo "-----------------------------------------------------------------------------------------"
echo "Angluar distance between event in 2 stations : $ang_dist [deg]"
echo "(RA,DEC)_mean                                : ( $mean_ra , $mean_dec ) [deg]"
echo "Desc                                         : $SATINFO in distance $SATDIST [arcsec] = $SATDIST_deg [degree]"
echo "Delay in time                                : $DELAT [sec]"
echo "Sun distance                                 : $DIST_sun [deg]"
echo "(Azim,elev)                                  : ($AZIM_mean,$ELEV_mean) [deg]"
echo "FITS FILES HIGH / LOW                        : $FITSFILE_highfreq   / $FITSFILE_lowfreq"
echo "Fluxes                                       : $Flux_high           / $Flux_low [Jy]"
echo "SNR                                          : $SNR_high            / $SNR_low"
echo "(RA,DEC)                                     : ($RA_high,$DEC_high) / ($RA_low,$DEC_low)"
echo "(X,Y)                                        : ($X_high,$Y_high)    / ($X_low,$Y_low)"
echo "Unixtime                                     : $UXTIME_high         / $UXTIME_low"
echo "DEBUG : $line"
echo "-----------------------------------------------------------------------------------------"
 