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
print "###############################################################################"


x_c_orig = x_c
y_c_orig = y_c

fitslist_data = pylab.loadtxt(fitslist,dtype='string')
# print "Read list of %d fits files from list file %s" % (fitslist_data.shape[0],fitslist)

out_file=open(outfile,"w")

line = ( "# Time-step Pixel_value X Y MAX_VALUE PIX_COUNT FITS_FILE SUM\n" )
out_file.write( line )


idx=0
for fitsfile in fitslist_data :
   fits = pyfits.open(fitsfile)
   x_size=fits[0].header['NAXIS1']
   y_size=fits[0].header['NAXIS2']
   dateobs=fits[0].header['DATE-OBS']
   
   if idx == 0 :
      if x_c < 0 :
         x_c = x_size / 2
         print("Set x_c = %d" % (x_c))
         
      if y_c < 0 :
         y_c = x_size / 2
         print("Set y_c = %d" % (y_c))
      
      x_c_orig = x_c
      y_c_orig = y_c   
         

   t=Time(dateobs)
   t_unix=t.replicate(format='unix')
   print "Read FITS file %s has dateobs = %s -> %.2f unixtime" % (fitsfile,dateobs,t_unix.value)
   

   data = None
#   if fits_type == 1 :
   if fits[0].data.ndim >= 4 :
      data = fits[0].data[0,0]
   else :
      data=fits[0].data

   sum = 0.00
   count = 0
   if radius > 0 :
       print "radius = %d -> finding maximum pixel around position (%d,%d)" % (radius,x_c,y_c)
   
       max_val = -1e6
       max_xc  = -1
       max_yc  = -1
   
       for yy in range( y_c_orig-radius , y_c_orig+radius+1 ) :
           for xx in range( x_c_orig-radius , x_c_orig+radius+1 ) :
               dist = m.sqrt( (yy-y_c_orig)**2 + (xx-x_c_orig)**2 )
           
               if dist < radius :
                   val = data[xx,yy]                   
                   sum += val
                   count += 1
                   if val > max_val :
                       max_val = val
                       max_xc = xx
                       max_yc = yy
                       print "\tDEBUG : max value = %.8f found at (%d,%d)" % (max_val,max_xc,max_yc)

       if max_xc > 0 and max_yc > 0 :
           x_c = max_xc
           y_c = max_yc 
          
           print "INFO : overwritting original position (%d,%d) with position of maximum value = %.2f at (%d,%d)" % (x_c_orig,y_c_orig,max_val,x_c,y_c)

   # data = fits[0].data[cc] # first dimension is coarse channel 
   pixel_value = data[x_c,y_c]
   pixel_count = 0 
   max_value = max_val

   # WARNING : aperture_radius > 0 - calculates max_value again and overwrites the earlier calculated one    
   if aperture_radius > 0 :
      max_value = -1e6
      pixel_sum = 0
      pixel_count = 0 
      for yy in range(y_c-aperture_radius,y_c+aperture_radius+1) :
         line = ""
         for xx in range(x_c-aperture_radius,x_c+aperture_radius+1) :
            if options.use_max_peak_flux : 
               if data[xx,yy] > pixel_sum :
                  pixel_sum = data[xx,yy]
            else : 
               pixel_sum = pixel_sum + data[xx,yy]
               pixel_count = pixel_count + 1
               
            if data[xx,yy] > max_value :
                max_value = data[xx,yy]   
               
            line = line + str( data[xx,yy] ) + " "
            
         if options.verbose > 1 :
            print line
            
      if options.verbose > 0 :
         print "pixel_sum := %.4f / %d = %.4f vs. max pixel = %.4f" % (pixel_sum,pixel_count,(pixel_sum / pixel_count),data[x_c,y_c])
                  
      pixel_sum = pixel_sum / pixel_count
      sum = pixel_sum

   if options.verbose > 0 :
      print "(%d,%d) = %.4f Jy" % (x_c,y_c,pixel_value)                                                                                       

   # time_value = t_unix.value
   time_value = idx*options.time_step
   if options.use_raw_value :
      time_value = idx

#   if count > 0 :
#      sum = sum / count      
   line = ( "%.4f %.4f %d %d %.4f %d %s %.8f\n" % (time_value,pixel_value,x_c,y_c,max_value,pixel_count,fitsfile,sum))
   out_file.write(line)
   
   idx = idx + 1 
                                                                                       

out_file.close()
print "Saved to file %s" % outfile
