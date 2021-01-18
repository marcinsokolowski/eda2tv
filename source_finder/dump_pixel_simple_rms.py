#!/opt/caastro/ext/anaconda/bin/python

# based on examples
# http://docs.astropy.org/en/stable/io/fits/ 
# https://python4astronomers.github.io/astropy/fits.html

import astropy.io.fits as pyfits
import pylab
import math as m
from array import *
import matplotlib.pyplot as plt
import numpy as np
import string
import sys
import os
import errno
import getopt
from astropy.time import Time
import optparse

# TIME_STEP=1 # one seconds images

def mkdir_p(path):
   try:
      cmd="mkdir -p %s" % path
      os.system(cmd)
      os.makedirs(path)
   except OSError as exc: # Python >2.5
      if exc.errno == errno.EEXIST:
         pass
   else: raise
                                 

fitslist="list"
if len(sys.argv) > 1:
   fitslist = sys.argv[1]   

x_c=-1
if len(sys.argv) > 2 and sys.argv[2][0] != "-" :
   x_c = int(sys.argv[2])
   
y_c=-1
if len(sys.argv) > 3 and sys.argv[3][0] != "-" :
   y_c = int(sys.argv[3])

outdir= "timeseries"
if len(sys.argv) > 4 and sys.argv[4] != "-" :
   outdir = sys.argv[4]

# if len(sys.argv) > 6:
#   outfile = sys.argv[6]


parser=optparse.OptionParser()
parser.set_usage("""dump_pixel_simple.py""")
parser.add_option("--radius","-r",dest="radius",default=2,help="Find maximum pixel in radius around given position [default: %default]",type="int")
parser.add_option("--ap_radius","-a","--aperture","--aperture_radius",dest="aperture_radius",default=0,help="Sum pixels in aperture radius [default: %default]",type="int")
parser.add_option("--verbose","-v","--verb",dest="verbose",default=0,help="Verbosity level [default: %default]",type="int")
parser.add_option("--outfile","-o",dest="outfile",default=None,help="Output file name [default:]",type="string")
parser.add_option('--use_max_flux','--use_max_peak_flux','--max_flux',dest="use_max_peak_flux",action="store_true",default=False, help="Use maximum flux value around the source center [default %]")
parser.add_option('--idx','--index','--raw',dest="use_raw_value",action="store_true",default=False, help="Use image index [default %s]")
parser.add_option("--time_step","-t",dest="time_step",default=1,help="Time resolution of FITS images [default: %default]",type="float")
parser.add_option("--channel","-c","--ch",dest="channel",default=294,help="Channel [default: %default]",type="int")
(options,args)=parser.parse_args(sys.argv[1:])
mkdir_p(outdir)

outfile="%s/pixel_%03d_%03d.txt" % (outdir,x_c,y_c)
if options.outfile is not None :
   outfile = options.outfile
   
radius=options.radius

aperture_radius=options.aperture_radius
if options.outfile is not None :
   outfile = options.outfile

print "###############################################################################"
print "PARAMETERS:"
print "###############################################################################"
print "Finding maximum pixel around position (x_c,y_c) = (%.2f,%.2f) in radius %d pixels" % (x_c,y_c,radius)
print "aperture_radius  = %d" % (aperture_radius)
print "use_max_peak_flux = %s" % (options.use_max_peak_flux)
print "outfile = %s" % (outfile)
print "use_raw_value = %s" % (options.use_raw_value)
print "Channel = %d" % (options.channel)
print "###############################################################################"


x_c_orig = x_c
y_c_orig = y_c

fitslist_data = pylab.loadtxt(fitslist,dtype='string')
# print "Read list of %d fits files from list file %s" % (fitslist_data.shape[0],fitslist)

out_file=open(outfile,"w")

line = ( "# Time-step Pixel_value X Y MAX_VALUE PIX_COUNT FITS_FILE SUM UXTIME\n" )
out_file.write( line )


idx=0
for fitsfile in fitslist_data :
   fits = pyfits.open(fitsfile)
   x_size=fits[0].header['NAXIS1']
   y_size=fits[0].header['NAXIS2']
   dateobs=fits[0].header['DATE-OBS']
   
   x_c = x_size / 2
   print("Set x_c = %d" % (x_c))
         
   y_c = x_size / 2
   print("Set y_c = %d" % (y_c))
      
   x_c_orig = x_c
   y_c_orig = y_c   
         

   t=Time(dateobs)
   t_unix=t.replicate(format='unix')
   print "Read FITS file %s has dateobs = %s -> %.2f unixtime" % (fitsfile,dateobs,t_unix.value)   
   
#   coord = SkyCoord( options.ra, options.dec, equinox='J2000',frame='icrs', unit='deg')
#   coord.location = MWA_POS
#   utc=fitsfile[9:24]  
#   uxtime = time.mktime(datetime.datetime.strptime(utc, "%Y%m%dT%H%M%S").timetuple()) + 8*3600 # just for Perth !!!
#   coord.obstime = Time( uxtime, scale='utc', format="unix" )
   

   data = None
#   if fits_type == 1 :
   if fits[0].data.ndim >= 4 :
      data = fits[0].data[0,0]
   else :
      data=fits[0].data

   sum = 0.00
   count = 0
   max_val = data[x_c,y_c]
   # data = fits[0].data[cc] # first dimension is coarse channel 
   pixel_value = data[x_c,y_c]
   pixel_count = 0 
   max_value = max_val

   if options.verbose > 0 :
      print "(%d,%d) = %.4f Jy" % (x_c,y_c,pixel_value)                                                                                       

   # time_value = t_unix.value
   time_value = idx*options.time_step
   if options.use_raw_value :
      time_value = idx

#   if count > 0 :
#      sum = sum / count      
   x_offset_20deg = 40
   x_offset_30deg = 60
   x_offset_45deg = 83
   x_offset_75deg = 111
   
   if options.channel == 204 :
      x_offset_20deg = 27
      x_offset_30deg = 38
      x_offset_45deg = 50
      x_offset_75deg = 73
    

   line = ( "%.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f\n" % (t_unix.value,\                                            # 1
                                                 data[x_c,y_c],                                                                                                        # 2 
                                                 data[x_c,y_c+x_offset_20deg],data[x_c,y_c+x_offset_30deg],data[x_c,y_c+x_offset_45deg],data[x_c,y_c+x_offset_75deg],\ # 3   4  5  6 
                                                 data[x_c,y_c-x_offset_20deg],data[x_c,y_c-x_offset_30deg],data[x_c,y_c-x_offset_45deg],data[x_c,y_c-x_offset_75deg],\ # 7   8  9 10
                                                 data[x_c+x_offset_20deg,y_c],data[x_c+x_offset_30deg,y_c],data[x_c+x_offset_45deg,y_c],data[x_c+x_offset_75deg,y_c],\ # 11 12 13 14
                                                 data[x_c-x_offset_20deg,y_c],data[x_c-x_offset_30deg,y_c],data[x_c-x_offset_45deg,y_c],data[x_c-x_offset_75deg,y_c])\ # 15 16 17 18
                                                 )
   out_file.write(line)
   
   idx = idx + 1 
                                                                                       

out_file.close()
print "Saved to file %s" % outfile
