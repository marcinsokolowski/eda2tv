#!/opt/caastro/ext/anaconda/bin/python

# based on examples
# http://docs.astropy.org/en/stable/io/fits/ 
# https://python4astronomers.github.io/astropy/fits.html

from __future__ import print_function

import astropy.io.fits as pyfits
from astropy import units as u
from astropy.coordinates import SkyCoord, EarthLocation
from astropy.time import Time
import time
import datetime


import pylab
import math
from array import *
import matplotlib.pyplot as plt
import numpy
import string
import sys
import os
import errno
import getopt
from astropy.time import Time
import optparse
import sky2pix


def mkdir_p(path):
   try:
      cmd="mkdir -p %s" % path
      os.system(cmd)
      os.makedirs(path)
   except OSError as exc: # Python >2.5
      if exc.errno == errno.EEXIST:
         pass
   else: raise
                                 

# CONSTANTS :
MWA_POS=EarthLocation.from_geodetic(lon="116:40:14.93",lat="-26:42:11.95",height=377.8)

# last_processed_filestamp = "dump_pixel_radec.last_processed"

fitslist="list"
if len(sys.argv) > 1:
   fitslist = sys.argv[1]   

parser=optparse.OptionParser()
parser.set_usage("""dump_pixel_simple.py""")
parser.add_option("--ra","--RA","--Ra",dest="ra",default=229.75,help="RA in degrees [default: %default]",type="float")
parser.add_option("--dec","--DEC","--Dec",dest="dec",default=12.33333333,help="DEC in degrees [default: %default]",type="float")
parser.add_option("--radius","-r",dest="radius",default=15,help="Find maximum pixel in radius around given position [default: %default]",type="int")
parser.add_option("--min_alt","--min_elev","--min_elevation",dest="min_elevation",default=1.00,help="Minimum object elevation [default: %default]",type="float")

parser.add_option('--calc_bkg','--calc_rms','--rms',dest="calc_rms",action="store_true",default=False, help="If calculate local RMS [default %s]")
parser.add_option("--rms_inner_radius",dest="rms_inner_radius",default=5,help="RMS inner radius [default: %default]",type="int")
parser.add_option("--rms_outer_radius",dest="rms_outer_radius",default=10,help="RMS outer radius [default: %default]",type="int")

parser.add_option("--verbose","-v","--verb",dest="verbose",default=0,help="Verbosity level [default: %default]",type="int")

parser.add_option("--outfile","-o",dest="outfile",default="pixel.txt",help="Output file name [default:]",type="string")
parser.add_option('--all','--force_all',dest="force_all",action="store_true",default=False, help="Force all (ignore last file) [default %s]")


parser.add_option("--last_processed_filestamp","--last_file",'--last_processed_file',dest="last_processed_filestamp",default="dump_pixel_radec.last_processed",help="Last processed filename [default %default]",type="string")


# parser.add_option('--use_max_flux','--use_max_peak_flux','--max_flux',dest="use_max_peak_flux",action="store_true",default=False, help="Use maximum flux value around the source center [default %]")
# parser.add_option('--idx','--index','--raw',dest="use_raw_value",action="store_true",default=False, help="Use image index [default %s]")
(options,args)=parser.parse_args(sys.argv[1:])
# mkdir_p(outdir)

print("###############################################################################")
print("PARAMETERS:")
print("###############################################################################")
print("Finding maximum pixel around position (ra,dec) = (%.4f,%.4f) in radius %d pixels" % (options.ra,options.dec,options.radius))
print("RMS calculation inner and outer radius : %d / %d pixels" % (options.rms_inner_radius,options.rms_outer_radius))
print("outfile = %s" % (options.outfile))
print("min_elevation = %.4f [deg]" % (options.min_elevation))
print("force_all = %s" % (options.force_all))
# print "use_raw_value = %s" % (options.use_raw_value)
print("###############################################################################")


fitslist_data = pylab.loadtxt(fitslist,dtype='S') # python2 - string ; python3 - S and later needs conversion to string using .decode("utf-8")
# fitslist_data = pylab.loadtxt(fitslist)
# print "Read list of %d fits files from list file %s" % (fitslist_data.shape[0],fitslist)

b_header = False
if not os.path.exists( options.outfile ) :
   b_header = True

out_file=open(options.outfile,"a+")
# line = ( "%.4f %.4f %.4f %d %d %.4f %s\n" % (t_unix.value,max_value,pixel_value,x_c,y_c,rms,fitsfile))

if b_header :
   line = "# UNIX_TIME   PIXEL_VAL MAX_VAL(r=%d) DIFF_VAL XC YC RMS_IQR RMS FITS_FILE ALT[deg] PIX_CNT \n" % (options.radius)
   out_file.write(line)

# READ last processed file :
last_processed_fitsname = None
if os.path.exists( options.last_processed_filestamp ) :
    file=open( options.last_processed_filestamp ,'r')
    
    # reads the entire file into a list of strings variable data :
    data=file.readlines()
    for line in data : 
       line = line. rstrip('\n')
       words = line.split(' ')

       if line[0] == '#' or len(line)<2 :
         continue
       
       last_processed_fitsname = line  

    print("DEBUG : last processed file = %s" % (last_processed_fitsname))

prev_pixel_value = None 
idx=0
for fitsfile_bytes in fitslist_data :
   fitsfile = fitsfile_bytes.decode("utf-8")
   
   do_write = True
   if not options.force_all : 
      if last_processed_fitsname is not None and fitsfile < last_processed_fitsname :
         print("File %s < last processed = %s" % (fitsfile,last_processed_fitsname))
         if fitsfile == last_processed_fitsname :
            do_write = False # not to reapet, but read the last processed file to have difference != 0 !!!
         continue
      

   last_f = open( options.last_processed_filestamp , "w" )
   last_f.write( fitsfile + "\n" )
   last_f.close()
   print("DEBUG : saved last processed fits name %s to file %s" % (fitsfile,options.last_processed_filestamp))
   
  
   print("Reading fits file %s" % (fitsfile))
   fits = pyfits.open(fitsfile)
   x_size=fits[0].header['NAXIS1']
   y_size=fits[0].header['NAXIS2']
   dateobs=fits[0].header['DATE-OBS']

   t=Time(dateobs)
   t_unix=t.replicate(format='unix')
   
   coord = SkyCoord( options.ra, options.dec, equinox='J2000',frame='icrs', unit='deg')
   coord.location = MWA_POS
#            coord.obstime = Time("20200507T065634", scale='utc', format="utc" )
            # chan_294_20200507T065634_I.fits
   utc=fitsfile[9:24]  
   uxtime = time.mktime(datetime.datetime.strptime(utc, "%Y%m%dT%H%M%S").timetuple()) + 8*3600 # just for Perth !!!
   coord.obstime = Time( uxtime, scale='utc', format="unix" )
   altaz = coord.transform_to('altaz')
   az, alt = altaz.az.deg, altaz.alt.deg
   
   if alt < options.min_elevation :
      print("%s : altitude = %.4f [deg] < min_alt = %.4f [deg] -> skipped" % (fitsfile,alt,options.min_elevation))
      continue

   
   (x_c0,y_c0) = sky2pix.sky2pix( fits, options.ra, options.dec )

   # this is because function sky2pix.sky2pix returns values directly as in ds9 (same WCS) , so for python/C code subtraction of 1 is needed :   
   x_c0_new = x_c0 - 1
   y_c0_new = y_c0 - 1
   
   print("Read FITS file %s has dateobs = %s -> %.2f unixtime , (%.4f,%.4f) [deg] -> (%.2f,%.2f) [pixels in ds9 convention] -> (%.2f,%.2f) [pixels in python/C convention]" % (fitsfile,dateobs,t_unix.value,options.ra,options.dec,x_c0,y_c0,x_c0_new,y_c0_new))
   
   x_c0 = x_c0_new
   y_c0 = y_c0_new
   
#   x_c = int( numpy.round(x_c0) )
#   y_c = int( numpy.round(y_c0) )
   x_c = -1000
   y_c = -1000
   if not numpy.isnan(x_c0) and not numpy.isnan(y_c0) :
      x_c = int( numpy.round(x_c0) )
      y_c = int( numpy.round(y_c0) )  
   else :
      print("WARNING : (RA,DEC) = (%.4f,%.4f) converted to (x,y) gives at least one NaN value -> %s skipped" % (options.ra, options.dec, fitsfile))
      continue
   
   data = None
#   if fits_type == 1 :
   if fits[0].data.ndim >= 4 :
      data = fits[0].data[0,0]
   else :
      data=fits[0].data

   pixel_value = data[y_c,x_c]
   sum = pixel_value
   count = 1   
   max_val = pixel_value
   max_xc  = x_c
   max_yc  = y_c
   if options.radius > 0 :
       print("radius = %d -> finding maximum pixel around position (%d,%d)" % (options.radius,x_c,y_c))
   
       for yy in range( y_c-options.radius , y_c+options.radius+1 ) :
           for xx in range( x_c-options.radius , x_c+options.radius+1 ) :
               dist = math.sqrt( (yy-y_c)**2 + (xx-x_c)**2 )
           
               if dist < options.radius :
                   val = data[yy,xx]                   
                   sum += val
                   count += 1
                   if val > max_val :
                       max_val = val
                       max_xc = xx
                       max_yc = yy

#       if max_xc > 0 and max_yc > 0 :
#           x_c = max_xc
#           y_c = max_yc 
          
#           print "INFO : overwritting original position (%d,%d) with position of maximum value = %.2f at (%d,%d)" % (x_c,y_c,max_val,x_c,y_c)

   rms = -1000.00
   pixel_count = 0
   pixel_sum = 0.00
   pixel_sum2 = 0.00
   max_noise   = -1e20   
   iqr = -1000
   rms_iqr = -1000
   if options.calc_rms :
      rms_pixels = []
   
      for yy in range(y_c-options.rms_outer_radius,y_c+options.rms_outer_radius+1) :
         line = ""
         for xx in range(x_c-options.rms_outer_radius,x_c+options.rms_outer_radius+1) :
            dist = math.sqrt( (xx-x_c)*(xx-x_c) + (yy-y_c)*(yy-y_c) )
            
            if dist >= options.rms_inner_radius and dist <= options.rms_outer_radius :         
               val = data[yy,xx]
               rms_pixels.append( val )
               pixel_sum = pixel_sum + val
               pixel_sum2 = pixel_sum2 + val*val
               pixel_count = pixel_count + 1
               
               if val > max_noise :
                   max_noise = val 
               
               line = line + str( val ) + " "
            
         if options.verbose > 1 :
            print(line)
            
      if options.verbose > 0 :
         print("pixel_sum := %.4f / %d = %.4f vs. max pixel = %.4f" % (pixel_sum,pixel_count,(pixel_sum / pixel_count),pixel_value))
                  
      # pixel_sum = pixel_sum / pixel_count
      # sum = pixel_sum
      rms_pixels=numpy.array( rms_pixels )
      rms_pixels.sort()
      q75= int(len(rms_pixels)*0.75);
      q25= int(len(rms_pixels)*0.25);

      
      mean_noise = pixel_sum / pixel_count
      rms = math.sqrt( pixel_sum2/pixel_count - (mean_noise*mean_noise) )
      iqr = rms_pixels[q75] - rms_pixels[q25] 
      rms_iqr = iqr/1.35;

   if options.verbose > 0 :
      print("(%d,%d) = %.4f Jy" % (x_c,y_c,pixel_value))                                                                                       

   # time_value = t_unix.value
#   time_value = idx*0.5   
#   if options.use_raw_value :
#      time_value = idx

#   if count > 0 :
#      sum = sum / count      
   diff_value = 0.00
   if prev_pixel_value is not None :
      diff_value = pixel_value - prev_pixel_value

   if do_write and idx > 0 :
      line = ( "%.4f %.4f %.4f %.4f %d %d %.4f %.4f %s %.2f %d %.4f %.4f %.4f %.4f %.4f\n" % (t_unix.value,pixel_value,max_val,diff_value,x_c,y_c,rms_iqr,rms,fitsfile,alt,pixel_count,pixel_sum,pixel_sum2,max_noise,iqr,rms_iqr))
      out_file.write(line)
      print("\t\t%s" % (line))
   
   idx = idx + 1 
   prev_pixel_value = pixel_value
                                                                                       

out_file.close()
print("Saved to file %s" % options.outfile)
