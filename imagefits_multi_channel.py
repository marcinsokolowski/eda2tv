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

# import pdb

from __future__ import print_function

import time
start_time0=time.time()

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
   parser.add_option('--reg_postfix','--reg_ext',dest="reg_postfix",default=".reg",help="Region file to use [default %default]")
   parser.add_option('--fits_list','--list_file','--list','--fitslist',dest="fitslist_file",default=None, help="FITS list file [default %default]")
   parser.add_option('--every_n_fits',dest="every_n_fits",default=1,help="Every N-th file to be converted [default %default",type="int")
   parser.add_option('--force',dest="skip_existing",action='store_false',default=True,help="Force over-writting jpg file [default %default]")
   
   (options,args) = parser.parse_args(sys.argv[2:])
   
   return (options,args)


def read_list( list_filename ) :
   out_fits_list=[]

   print("read_list : reading file %s" % (list_filename))

   if os.path.exists( list_filename ) and os.stat( list_filename ).st_size > 0 :
      file=open( list_filename ,'r')
      data=file.readlines()
      for line in data :
         line=line.rstrip()
         words = line.split(' ')
         if line[0] == '#' :
            continue

         if line[0] != "#" :
            uvbase = words[0+0] 
            if uvbase.find(".fits") < 0 :
               uvfits_x = uvbase + "_XX.fits"
               uvfits_y = uvbase + "_YY.fits"


               out_fits_list.append( uvfits_x )
#               out_fits_list.append( uvfits_y )

#               print("DEBUG : added %s and %s" % (uvfits_x,uvfits_y))
               print("DEBUG : added %s" % (uvfits_x))
            else :
               out_fits_list.append( uvbase )
               print("DEBUG : added %s" % (uvbase))
      file.close()
   else :
      print("WARNING : empty or non-existing file %s" % (list_filename))


   return out_fits_list


if __name__ == '__main__':
   start_time = time.time()
   print("fixCoordHdr.py : import took %.6f [seconds]" % (start_time-start_time0))


   filename="start_timeindex0564_ux1521883954.20.fits"
   if len(sys.argv) > 1:   
      filename = sys.argv[1]

   (options,args) = parse_options(0)
   
   print("###########################################")
   print("PARAMETERS :")
   print("###########################################")
   print("Every N-th file = %d" % (options.every_n_fits))
   print("###########################################")
   
   fits_list=[]
   if options.fitslist_file is not None :
      fits_list=read_list( options.fitslist_file )      
   else :
      fits_list.append(filename)
            
   idx=0      
   for filename in fits_list :       
      if (idx % options.every_n_fits) == 0 :   
         file_start_time=time.time()
      
         jpgfile=filename.replace('.fits', '.'+options.image_format )
         jpg_path=options.outdir + "/" + jpgfile
         regfile=filename.replace('.fits', options.reg_postfix )
         
         if options.skip_existing :
            if os.path.exists( jpg_path ) :
               print("INFO : file %s already exists -> skipped" % (jpg_path))
               continue


         if len(fits_list) == 1 :
            if options.outfile is not None :
               jpgfile = options.outfile
   
         if options.regfile is not None :
            regfile = options.regfile   

         print("DEBUG : converting file %s -> %s , %s" % (filename,jpgfile,regfile))

         hdu_list = fits.open(filename)
         hdu_list.info()
   
         image_data = hdu_list[0].data[0]
         n_chan=hdu_list[0].data.shape[1]
         header=hdu_list[0].header
         wcs = WCS( header )
         dim=wcs.naxis
#      print(image_data.shape)
         naxes=header['NAXIS']
         print("DEBUG : dim = %d vs. naxes = %d" % (dim,naxes))
   
         for ch in range(0,n_chan) :
            jpg_path="%s/channel_%03d.jpg" % (jpg_path=options.outdir,ch)
            image_data = hdu_list[0].data[0,ch]

            if options.window is not None : 
               print("Using only sub-window (%d,%d)-(%d,%d) of the full image" % (options.window[0],options.window[1],options.window[2],options.window[3]))
               image_data2=image_data[options.window[0]:options.window[2],options.window[1]:options.window[3]].copy()
               image_data = image_data2
   
            fig = plt.figure( figsize=(200, 60), dpi = options.dpi )
            ax = fig.add_subplot(111, projection=wcs)
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
      
            cbar = plt.colorbar()
            cbar.ax.tick_params(labelsize=60)

            # image title (fits file name) : 
            # OLD (before 20190909) :
            # plt.text(x_size/3,-10,filename)
   

            plt.text(-0.9,0.5,filename, horizontalalignment='center', verticalalignment='center', transform=ax.transAxes,fontsize=100)
            plt.grid(color='white', ls='solid', linewidth=5)

            mkdir_p( options.outdir )
            # fig=plt.figure()
            # plt.plotfile(filename,(0,1),delimiter=" ",names="Frequency [MHz],T[K]",newfig=False)
            plt.savefig( jpg_path , format = options.image_format, dpi = fig.dpi)
            plt.close('all')
            file_end_time=time.time()
         
            print("DEBUG : saved file %s (processing took %.4f [seconds])" % (jpg_path,(file_end_time-file_start_time)))         
      else :
         print("DEBUG : idx = %d -> skipped (due to modulo %d required)" % (idx,options.every_n_fits))
         
      idx += 1


   end_time = time.time()
   print("fixCoordHdr.py: Start_time = %.6f , end_time = %.6f -> took = %.6f seconds (including import took %.6f seconds)" % (start_time,end_time,(end_time-start_time),(end_time-start_time0)))
