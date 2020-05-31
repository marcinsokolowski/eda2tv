#!/opt/caastro/ext/anaconda/bin/python

from __future__ import print_function
import astropy.io.fits as pyfits
from astropy.coordinates import SkyCoord, EarthLocation
from astropy.time import Time
import optparse


# TEMPORARY ???
from astropy.utils.iers import conf
conf.auto_max_age = None


import pylab
import math 
from array import *
import matplotlib.pyplot as plt
import numpy as np
import string
import sys
import os
import errno
import getopt

# global parameters :
debug=0
fitsname="file.fits"
out_fitsname="scaled.fits"
do_show_plots=0
do_gif=0

center_x=1025
center_y=1025
radius=600

def mkdir_p(path):
   try:
      os.makedirs(path)
   except OSError as exc: # Python >2.5
      if exc.errno == errno.EEXIST:
         pass
      else: raise
                                            
def parse_options(idx=0):
   parser=optparse.OptionParser()
   parser.set_usage("""fixCoordHdr.py FITS_FILE --remove_keywords""")
   
   parser.add_option('-r','-R','--remove_axis',dest="remove_axis",default=True, action="store_true", help="Remove axis 3 and 4 keywords [default %default]")
   parser.add_option('-l','-L','--lst_hours',dest="lst_hours",default=-100,help="LST [hours] [default %default]");

   (options,args) = parser.parse_args( sys.argv[idx:] )

   return (options,args)


if __name__ == '__main__':
   # 
   if len(sys.argv) > 1:
      fitsname = sys.argv[1]

#   lst_hours=-100 # by default LST is automatically calculated from FITS file
#   if len(sys.argv) > 2:
#      lst_hours = float(sys.argv[2])
      
   (options,args) = parse_options(1)   
   lst_hours = options.lst_hours
   remove_axis = options.remove_axis
   


   deg2rad=math.pi/180.00
   lat_deg=-26.703319
   lat_radian=lat_deg*deg2rad
   
   print("####################################################")
   print("PARAMTERS :")
   print("####################################################")
   print("fitsname       = %s"   % fitsname)
   print("lst            = %.8f [hours]" % lst_hours)
   print("lat            = %.4f [deg] = %.4f [rad]" % (lat_deg,lat_radian))
   print("remove axis    = %s" % (remove_axis))
   print("####################################################")

   fits = pyfits.open(fitsname)
   x_size=fits[0].header['NAXIS1']
   # channels=100
   y_size=fits[0].header['NAXIS2']

#   if remove_axis :
#      fits[0].header['NAXIS'] = 2
#      fits[0].header.remove('NAXIS3')
#      fits[0].header.remove('NAXIS4')

   if lst_hours < 0 :
      dateobs=fits[0].header['DATE-OBS']
      print("LST hours parameter = %.4f [h] < 0 -> getting lst from fits file automatically using DATE-OBS = %s UTC" % (lst_hours,dateobs))
      MWA_POS=EarthLocation.from_geodetic(lon="116:40:14.93",lat="-26:42:11.95",height=377.8)
      t = Time( dateobs, scale='utc', location=(MWA_POS.lon.value, MWA_POS.lat.value ))
      lst_hours = t.sidereal_time('apparent').value
      print("Lst hours from dateobs = %s -> lst = %.8f [h]" % (dateobs,lst_hours))

   ra_center_deg=fits[0].header['CRVAL1']
   dec_center_deg=fits[0].header['CRVAL2']

   dec_center_rad=dec_center_deg*deg2rad
   ra_center_rad=ra_center_deg*deg2rad
   ra_center_h=ra_center_deg/15.0

   ha_hours=lst_hours-(ra_center_deg/15.00)
   ha_radians=(ha_hours*15.00)*deg2rad

   print("values = %.8f %.8f %.8f , %.8f" % (lat_radian,ra_center_rad,dec_center_rad,ha_radians))
   cosZ=math.sin(lat_radian)*math.sin(dec_center_rad) + math.cos(lat_radian)*math.cos(dec_center_rad)*math.cos(ha_radians)
   tanZ=math.sqrt(1.00-cosZ*cosZ)/cosZ

   print("tanZ = %.8f" % tanZ)

   # Parallactic angle
   # http://www.gb.nrao.edu/~rcreager/GBTMetrology/140ft/l0058/gbtmemo52/memo52.html
   tan_chi=math.sin(ha_radians)/( math.cos(dec_center_rad)*math.tan(lat_radian) - math.sin(dec_center_rad)*math.sin(ha_radians)  ) 

   # $lat_radian $dec_radian $ha_radian
   print("DEBUG : values2 : %.8f %.8f %.8f" % (lat_radian,dec_center_rad,ha_radians))
   chi_radian=math.atan2( math.sin(ha_radians) , math.cos(dec_center_rad)*math.tan(lat_radian) - math.sin(dec_center_rad)*math.cos(ha_radians) )

   print("chi_radian = %.8f" % chi_radian)

   # there is a - sign in the paper, but Randall says it's possibly wrong:
   # so I stay with NO - SIGN version
   xi=tanZ*math.sin(chi_radian)
   eta=tanZ*math.cos(chi_radian)

   fits[0].header['PV2_1'] = xi
   fits[0].header['PV2_2'] = eta
   header = fits[0].header

   if options.remove_axis :
      removed = False
      for keyword in ['CUNIT3','CDELT3','CRVAL3','CRPIX3','CTYPE3','NAXIS3','CUNIT4','CDELT4','CRVAL4','CRPIX4','CTYPE4','NAXIS4'] :
         try :
            if header.count( keyword ) > 0 :
                print("DEBUG : removing keyword |%s|" % (keyword))
                # fits[0].header.remove( keyword )
                header.remove( keyword )
                removed = True
         except :
            print("WARNING : could not remove keyword = %s" % (keyword))
            
      if removed : 
         data2=fits[0].data[0,0].copy()
         fits[0].data=data2



# CTYPE1  = 'RA---SIN'
# CRVAL1  =   1.193772717790E+02
# CDELT1  =  -3.333333333333E-02
# CRPIX1  =   5.010000000000E+02
# CUNIT1  = 'deg     '
# CTYPE2  = 'DEC--SIN'
# CRVAL2  =   1.648915631751E+00
# CDELT2  =   3.333333333333E-02
# CRPIX2  =   5.010000000000E+02
# CUNIT2  = 'deg     '


   print("Writing xi = %.8f and eta = %.8f to fits header %s" % (xi,eta,fitsname))
   fits.writeto( fitsname, overwrite=True ) 
    


