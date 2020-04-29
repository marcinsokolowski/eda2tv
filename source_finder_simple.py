#!/opt/caastro/ext/anaconda/bin/python

# based on examples
# http://docs.astropy.org/en/stable/io/fits/ 
# https://python4astronomers.github.io/astropy/fits.html

import astropy.io.fits as pyfits
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
import find_gleam
from optparse import OptionParser,OptionGroup

# TODO :
# 0/ use parse_options and proper parameters not the mess as it is ...
# 1/ add local MEAN / RMS calculation - create rms.py or bkg.py module with : Interpolation or fitting a surface over a couple of points with locally (specified by radius parameter) calculated RMS 
#     See example in fit_surface_test.py
#    Emil used the same way : ~/Desktop/SKA/Tim/doc/Beam_Model/Beam_model_on_real_data/FINAL/paper/Emil/20170706/marcin/TEST/my/AFTER_EMIL_FIXES/CLEANED



def parse_options(idx):
   usage="Usage: %prog [options]\n"
   usage+='\tDedisperse images \n'
   parser = OptionParser(usage=usage,version=1.00)
#   parser.add_option('-m','--mean_cc',action="store_true",dest="mean_cc",default=True, help="Mean of coarse channels [default %]")
#   parser.add_option('--no_mean_cc',action="store_false",dest="mean_cc",default=True, help="Turn off calculation of mean of coarse channels [default %]")
#   parser.add_option('-o','--outdir',dest="outdir",default=None, help="Output directory [default %]")
#   parser.add_option('--meta_fits','--metafits',dest="metafits",default=None, help="Metafits file [default %]")

   (options, args) = parser.parse_args(sys.argv[idx:])

   return (options, args)



def find_source( x, y, list_x, list_y, radius=5 ):
   if len(list_x) != len(list_y) :
      print "ERROR : wrong list sizes !!!"
      return -1


   for i in range(0,len(list_x)) :
      x_ref = list_x[i]
      y_ref = list_y[i]
      
      if math.fabs(x-x_ref)<radius and math.fabs(y-y_ref)<radius :
         return i
         
   return -1

# ls wsclean_timeindex???/wsclean_1192530552_timeindex8-000?-I-dirty.fits > list_for_dedisp
listname="list_for_dedisp"
if len(sys.argv) > 1: 
  listname = sys.argv[1]

threshold=5
if len(sys.argv) > 2:
   threshold = float(sys.argv[2])
   
ref_image=None
if len(sys.argv) > 3 and sys.argv[3] != "-" :
   ref_image=sys.argv[3]

save_dynamic_spectrum_treshold=7
if len(sys.argv) > 4:
   save_dynamic_spectrum_treshold=int(sys.argv[4])

cube_fits=None
if len(sys.argv) > 5 and sys.argv[5] != "-" :
   cube_fits=sys.argv[5]

border=2
if len(sys.argv) > 6:
   border=int(sys.argv[6])
if border < 0 :
   border = 0   

radius_gleam_arcmin=-1 # 2 should be good
if len(sys.argv) > 7:
   radius_gleam_arcmin = int(sys.argv[7])

fits_type=0
radius=1
threshold_in_sigma=3
max_rms=1.00

do_simul=False

(options, args) = parse_options(8) 

print "##############################################################"
print "PARAMETERS :"
print "##############################################################"
print "listname                       = %s" % (listname)
print "ref_image                      = %s" % (ref_image)
print "cube_fits                      = %s" % (cube_fits)
print "threshold                      = %.2f x sigma" % (threshold)
print "save_dynamic_spectrum_treshold = %.2f x sigma" % (save_dynamic_spectrum_treshold)
print "image border                   = %d" % (border)
print "radius_gleam_arcmin            = %d   [arcmin]" % (radius_gleam_arcmin)
print "do_simul                       = %s" % (do_simul)
print "##############################################################"

if listname.find(".fits") >= 0 :
   print "Treating listname = %s as a single fits file" % (listname)
   f_tmp = open( "list_tmp" , "w" )
   f_tmp.write( ("%s\n" % listname) )
   f_tmp.close()
   listname="list_tmp"
   print "Processing single FITS file, written fits file %s to temporary list file list_tmp" % (listname)
else :
   print "Listname = %s is list of fits files" % (listname)

ref_image_list_x=[]
ref_image_list_y=[]

RA_map=None
Dec_map=None
gleam_sources=None
gleam_fluxes=None
radius_gleam_out=None

if ref_image is not None :
   if radius_gleam_arcmin > 0 :
      (RA_map,Dec_map,gleam_sources,gleam_fluxes,radius_gleam_out) = find_gleam.select_gleam_sources( ref_image )
      print "Selected %d GLEAM sources %.2f [deg] around image %s center" % (len(gleam_sources),radius_gleam_out,ref_image)

   if ref_image.find(".fits") >= 0 :
      fits = pyfits.open( ref_image )
      x_size=fits[0].header['NAXIS1']  
      y_size=fits[0].header['NAXIS2']              
               
      print 
      print '# \tRead reference fits file %s of size %d x %d' % (ref_image,x_size,y_size)

      data = None
      if fits_type == 1 :
         data = fits[0].data[0,0]
      else :
         data=fits[0].data


      # calculate MEAN/RMS :
      sum=0
      sum2=0
      count=0
      for y_c in range(radius,y_size-radius) :   
         for x_c in range(radius,x_size-radius) : 
            # count_test=0
            # final_value=0
            # for y in range (y_c-radius,(y_c+radius+1)):   
            #   for x in range (x_c-radius,(x_c+radius+1)):                              
            # value = data[y_c,x_c]
            # final_value = final_value + value
            #  count_test = count_test + 1               
            # final_value = final_value / count_test
            
            final_value=data[y_c,x_c]
            sum = sum + final_value
            sum2 = sum2 + final_value*final_value
            count = count + 1 
                        
            # print "count_test = %d" % (count_test)
   
      mean_val = (sum/count)
      rms = math.sqrt(sum2/count - mean_val*mean_val)
      print "%s : mean +/- rms = %.4f +/- %.4f (based on %d points)" % (ref_image,mean_val,rms,count)

      postfix_txt = ("_%.2fsigma.txt" % (threshold))
      postfix_reg = ("_%.2fsigma.reg" % (threshold))
      
      reffile=ref_image.replace('.fits', postfix_txt )
      regfile=ref_image.replace('.fits', postfix_reg )
      f_ref = open( reffile , "w" )
      f_reg = open( regfile , "w" )
      for y in range(0,y_size) :   
         for x in range(0,x_size) : 
            value = data[y,x]
         
            if value > mean_val + threshold*rms :            
               if find_source(x,y,ref_image_list_x,ref_image_list_y,radius=5) < 0 :
                  f_ref.write( "%d %d %.2f = %.2f sigma > %.2f x %.2f\n" % (x,y,value,(value/rms),threshold,rms) )
                  f_reg.write( "circle %d %d 5 # %.2f Jy\n" % ((x+1),(y+1),value) ) # (x+1),(y+1) - due to ds9 indexing from 1 
                  print "DEBUG (ref-regfile) : circle %d %d 5 # %.2f Jy\n" % (x,y,value)
            
                  ref_image_list_x.append(x)
                  ref_image_list_y.append(y)
               
                  
   
      print "%d sources found in reference image %s above threshold of %.2f sigma (= %.2f Jy)" % (len(ref_image_list_x),ref_image,threshold,(mean_val + threshold*rms))
            
      f_ref.close()
      f_reg.close()

   else : # just a list file to read :
      file=open(ref_image,'r')
      # reads the entire file into a list of strings variable data :
      data=file.readlines()
      for line in data : 
         words = line.split(' ')

         if line[0] == '#' :
            continue

         if line[0] != "#" :
            x=float(words[0+0])
            y=float(words[1+0])
      
            ref_image_list_x.append(x)
            ref_image_list_y.append(y)

      file.close()
      
      print "Read %d sources from reference list %s" % (len(ref_image_list_x),ref_image)

   print "Reference list of sources has %d sources:" % (len(ref_image_list_x))
   for s in range(0,len(ref_image_list_x)) :
      print "\t%d %d" % (ref_image_list_x[s],ref_image_list_y[s])
   

# x_c=250
# if len(sys.argv) > 1:
#   x_c = int(sys.argv[1])

# outdir="dedispersed/"
# os.system("mkdir -p dedispersed/")
os.system("mkdir -p dynamic_spectrum/")

f = open (listname,"r")

b_no_header=False
starttimeindex=0

while 1:
   fitsname = f.readline().strip()

   if not fitsname: 
      break
      
   # wsclean_timeindex008/wsclean_1192530552_timeindex8-0001-I-dirty.fits
   # timeidx=int(fitsname[17:20])
   # cc=int(fitsname[-17:-13])      

   fits = pyfits.open( fitsname )
   x_size=fits[0].header['NAXIS1']  
   y_size=fits[0].header['NAXIS2']              
   try : 
      starttimeindex=fits[0].header['STTIDX']
   except :
      print "WARNING : Keyword STTIDX not found in fits file %s (not needed)" % (fitsname)
      b_no_header = True
               
   print 
   print '# Read fits file %s of size %d x %d' % (fitsname,x_size,y_size)

   data = None
   if fits_type == 1 :
      data = fits[0].data[0,0]
   else :
      data=fits[0].data


   # calculate MEAN/RMS :
   sum=0
   sum2=0
   count=0
   y_center = y_size / 2
   x_center = x_size / 2
#   if search_radius_px <= 0 :
#      search_radius_px = ( x_size / 2 ) - 1 
   
   for y_c in range(border,y_size-border) :   
      for x_c in range(border,x_size-border) : 
         # count_test=0
         # final_value=0
         # for y in range (y_c-radius,(y_c+radius+1)):   
         #   for x in range (x_c-radius,(x_c+radius+1)):                              
         #      value = data[y,x]
         #      final_value = final_value + value
         #      count_test = count_test + 1               
         # final_value = final_value / count_test
         
         final_value = data[y_c,x_c]
         sum = sum + final_value
         sum2 = sum2 + final_value*final_value
         count = count + 1 
                        
         # print "count_test = %d" % (count_test)
   
   mean_val = (sum/count)
   rms = math.sqrt(sum2/count - mean_val*mean_val)
   thresh_value = mean_val + threshold*rms
   print "\t\t%s : mean +/- rms = %.4f +/- %.4f (based on %d points) -> threshold = %.2f , search window = (%d,%d)-(%d,%d)" % \
         (fitsname,mean_val,rms,count,thresh_value,border,border,x_size-border,y_size-border)
   

   if do_simul :
      # add value at random location :
      f_simul = open( "simul.txt" , "w" )
      x_simul = 75
      y_simul = 75
      simul_line = "%d %d" % (x_simul,y_simul)
      data[x_simul,y_simul] = 20*rms
      f_simul.write(simul_line)
      f_simul.close()


   postfix_txt = ("_%.2fsigma.txt" % (threshold))
   postfix_reg = ("_%.2fsigma.reg" % (threshold))

   regfile=fitsname.replace('.fits', postfix_reg )
   txtfile=fitsname.replace('.fits', postfix_txt )
   f_reg = open( regfile , "w" )
   f_txt = open( txtfile , "w" )
   for y in range(border,y_size-border) :   
      for x in range(border,x_size-border) : 
         value = data[y,x]
         
         if value > thresh_value :            
            new_source=True
            if len(ref_image_list_x) > 0 and ( gleam_sources is None or len(gleam_sources)<=0 ) :
               index = find_source(x,y,ref_image_list_x,ref_image_list_y,radius=5)
               if index>=0 :
                  new_source=False
               
               print "Checking source at (%d,%d) value = %.2f Jy ... FOUND=%s" % (x,y,value,(index>=0))
            else :
               print "INFO : checking only GLEAM (not reference image)"

            if gleam_sources is not None and len(gleam_sources) > 0 :
               new_source_ra  = RA_map[x,y]   # warning verify if order x,y should not be swaped 
               new_source_dec = Dec_map[x,y]  # warning verify if order x,y should not be swaped
               
               print "Checking source at (%d,%d) value = %.2f Jy in GLEAM, (ra,dec) = (%.4f,%.4f) [deg]" % (x,y,value,new_source_ra,new_source_dec)
               (gleam_source,gleam_flux,gleam_dist_arcsec) = find_gleam.find_source(gleam_sources,gleam_fluxes,new_source_ra,new_source_dec,radius_arcsec=radius_gleam_arcmin*60.00,flux_min=0)
               if gleam_source is not None :
                  print "\t\tFound in gleam source %s with flux = %.2f in distance = %.2f [arcsec]" % (gleam_source,gleam_flux,gleam_dist_arcsec)
                  new_source=False

            if new_source :
               n_sigmas=(value/rms)
               n_sigmas_int=int(n_sigmas)
               f_reg.write( "circle %d %d %d # %.2f Jy = %.2f sigmas (>=%.2f x %.2f + %.2f), %s\n" % ((x+1),(y+1),n_sigmas_int,value,((value-mean_val)/rms),threshold,rms,mean_val,fitsname) ) # (x+1),(y+1) - due to ds9 indexing from 1
               print "DEBUG (reg file) : circle %d %d %d # %.2f Jy = %.2f sigmas >= (%.2f x %.2f + %.2f), %s\n" % (x,y,n_sigmas_int,value,((value-mean_val)/rms),threshold,rms,mean_val,fitsname)
               f_txt.write( "%s %d %d %.2f = %.2f sigma > %.2f x %.2f\n" % (fitsname,x,y,value,(value/rms),threshold,rms) )
               
#               if value > mean_val + save_dynamic_spectrum_treshold*rms and cube_data is not None :
#                  hdu = pyfits.PrimaryHDU()
#                  hdu.data = np.zeros( (cube_channels,cube_timesteps))
#                  hdulist = pyfits.HDUList([hdu])                  
#                  for cube_cc in range(0,cube_channels):
#                     for cube_time in range(0,cube_timesteps):
#                        hdu.data[cube_cc,cube_time]=cube_data[cube_time,cube_cc,y,x]
#                  
#                  dynfile="dynamic_spectrum/start_timeindex%04d_%04d_%04d_%04dsigmas.fits" % (starttimeindex,x,y,n_sigmas_int)
#                  hdulist.writeto(dynfile,clobber=True)
#                  print "Saved dynamic spectrum of pixel (%d,%d) to file %s" % (x,y,dynfile)


   f_reg.close()
   f_txt.close()

   if b_no_header :
      starttimeindex += 1

fits.close()


f.close()