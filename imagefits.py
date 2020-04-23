#!/usr/bin/python

# pip install pyregion
# http://www.astropy.org/astropy-tutorials/FITS-images.html
# https://github.com/astropy/pyregion/blob/master/docs/getting_started.rst
# https://matplotlib.org/api/_as_gen/matplotlib.patches.Patch.html#matplotlib.patches.Patch.set_color
# https://media.readthedocs.org/pdf/pyregion/latest/pyregion.pdf
# 
# Useful :
# https://docs.astropy.org/en/stable/visualization/wcsaxes/
# https://docs.astropy.org/en/stable/wcs/

from __future__ import print_function
import matplotlib
matplotlib.use('Agg')


from astropy.io import fits
import pylab
import math as m
from array import *
import numpy as np
import string
import sys                                  
import os
import errno
# from astropy.io import fits
# from matplotlib.colors import LogNorm
import optparse

import matplotlib.pyplot as plt
import matplotlib.colors

# https://docs.astropy.org/en/stable/wcs/
from astropy.wcs import WCS

def mkdir_p(path):
   try:
      os.makedirs(path)
   except OSError as exc: # Python >2.5
      if exc.errno == errno.EEXIST:
         pass
      else: raise

def parse_options(idx):
   parser=optparse.OptionParser()
   parser.set_usage("""imagefits.py FITS_FILE --window 200 200 250 250""")
   parser.add_option('-w','--window',nargs = 4, dest="window",default=None, help="Window to make image [default %default]",type="int")
   parser.add_option('-t','-T','--transpose','--trans',dest="transpose",default=False, action="store_true", help="Transpose [default %default]")
   # parser.add_option("--radius","-r",dest="radius",default=0,help="Sum pixels in radius [default: %default]",type="int")
   # parser.add_option("--verbose","-v","--verb",dest="verbose",default=0,help="Verbosity level [default: %default]",type="int")
   parser.add_option("--outfile","-o",dest="outfile",default=None,help="Output file name [default:]",type="string")
   parser.add_option("--outdir","-d",dest="outdir",default="images/",help="Output directory name [default:]",type="string")
   parser.add_option("--regfile",dest="regfile",default=None,help="Region file [default: None]",type="string")
   parser.add_option('--dpi',dest="dpi",default=25, help="Image DPI [default %default]",type="int")
   parser.add_option('--out_format','--out_type','--ext','--out_image_type',dest="image_format",default="jpg", help="Output image type [default %default]")
   # parser.add_option('--use_max_flux','--use_max_peak_flux','--max_flux',dest="use_max_peak_flux",action="store_true",default=False, help="Use maximum flux value around the source center [default %]")
   
   (options,args) = parser.parse_args(sys.argv[2:])
   
   return (options,args)


if __name__ == '__main__':
   filename="start_timeindex0564_ux1521883954.20.fits"
   if len(sys.argv) > 1:   
      filename = sys.argv[1]

   (options,args) = parse_options(0)
   
   jpgfile=filename.replace('.fits', '.'+options.image_format )
   regfile=filename.replace('.fits', '.reg' )


   if options.outfile is not None :
      jpgfile = options.outfile
   
   if options.regfile is not None :
      regfile = options.regfile   

   hdu_list = fits.open(filename)
   hdu_list.info()
   
   image_data = hdu_list[0].data
   wcs = WCS(hdu_list[0].header)
   print(image_data.shape)
   image_data = fits.getdata(filename)
   if image_data.ndim >= 4 :
      image_data = fits.getdata(filename)[0,0]
   print(type(image_data))
   print(image_data.shape)

   if options.window is not None : 
      print("Using only sub-window (%d,%d)-(%d,%d) of the full image" % (options.window[0],options.window[1],options.window[2],options.window[3]))
      image_data2=image_data[options.window[0]:options.window[2],options.window[1]:options.window[3]].copy()
      image_data = image_data2
   
   #   if options.transpose :
   #      image_data = image_data2.transpose()

  # hdu_list.close()

   # histogram = plt.hist(image_data.flatten(), 1000) # 1000 bins 
   # histogram = plt.hist(image_data.flatten(), bins=100, range=[-2,2]) # 1000 bins
   # plt.show()


#   fig = plt.figure( figsize=(200, 60), dpi = options.dpi, tight_layout=True)
   fig = plt.figure( figsize=(200, 60), dpi = options.dpi )
# OLD   ax = fig.add_subplot(111, aspect='equal')
   ax = fig.add_subplot(111, projection=wcs)
   # plt.imshow(image_data, cmap='gray', norm=LogNorm())
   # GOOD : plt.imshow(image_data, cmap='gray', norm=matplotlib.colors.NoNorm())
   mean=image_data.mean()
   rms=image_data.std()
   x_size=image_data.shape[0]
   y_size=image_data.shape[1]

   if options.transpose :
      # cmap='gray'
      plt.imshow(image_data.transpose(),  vmin=mean-5*rms, vmax=mean+5*rms , origin='lower', cmap=plt.cm.viridis)
      y_size=image_data.shape[0]
      x_size=image_data.shape[1]
   else :
      # cmap='gray'
      plt.imshow(image_data, vmin=mean-5*rms, vmax=mean+5*rms , origin='lower', cmap=plt.cm.viridis)
#      plt.imshow(image_data, vmin=0.00, vmax=50000, origin='lower' , cmap=plt.cm.viridis)
      
   plt.colorbar()

   # image title (fits file name) : 
   # OLD (before 20190909) :
   # plt.text(x_size/3,-10,filename)
   

   if os.path.exists(regfile) and os.stat(regfile).st_size > 0 :
      import pyregion
      # r = pyregion.open(regfile)
      r = pyregion.open(regfile).as_imagecoord(header=hdu_list[0].header)
      if len(r) > 0 :
         patch_list, artist_list = r.get_mpl_patches_texts()
         print(r)
      
         for p in patch_list:
            if options.window is not None :
               xc=p.center[0]
               yc=p.center[1]
               
               p.center = (xc-options.window[0],yc-options.window[1])
               print("Changing center of the ellipse (%d,%d) -> (%d,%d)" % (xc,yc,p.center[0],p.center[1]))
      
            ax.add_patch(p)
            p.set_edgecolor("green")
            print(p)

   plt.text(-0.9,0.5,filename, horizontalalignment='center', verticalalignment='center', transform=ax.transAxes,fontsize=100)
   plt.grid(color='white', ls='solid')
#   plt.xlabel('RA' , fontsize=100)
#   plt.ylabel('Dec' , fontsize=100)

   mkdir_p( options.outdir )
   # fig=plt.figure()
   # plt.plotfile(filename,(0,1),delimiter=" ",names="Frequency [MHz],T[K]",newfig=False)
   plt.savefig( options.outdir + "/" + jpgfile, format = options.image_format, dpi = fig.dpi)
