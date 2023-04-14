# https://stackoverflow.com/questions/18721762/matplotlib-polar-plot-is-not-plotting-where-it-should
# import numpy as np
# import matplotlib.pyplot as plt

from __future__ import print_function

import gc # garbage collector
import matplotlib
# matplotlib.use('Agg')

from string import Template
import os
import sys
import errno
import matplotlib.pyplot as plt

t = Template("$EDA2TV_PATH/coinc")
new_import_path=t.substitute(os.environ)
sys.path.append( new_import_path )
print("Added import path %s" % new_import_path)
import eda2_aavs2_concidence 
import numpy as np

# options :
from optparse import OptionParser,OptionGroup


def read_list_file( listfile ) :
   file=open(listfile,'r')

   # reads the entire file into a list of strings variable data :
   data=file.readlines()
   files=[]

   for line in data : 
      words = line.split(' ')

      if line[0] == '#' :
         continue

      if line[0] != "#" :
        filename=words[0+0]

      files.append(filename.strip())
      
   return (files)   

def generate_plot(Az,El,options,imagefile="out.jpg"):
    outfile=options.outdir + "/" + imagefile
    
    if not os.path.exists(outfile) :
       fig = plt.figure( figsize=(10, 10) ,  dpi = options.dpi )
#    fig = plt.figure( figsize=(100, 30), dpi = options.dpi, tight_layout=True)
    # ax = fig.add_subplot(111, aspect='equal')
       ax = fig.add_axes([0.1, 0.1, 0.8, 0.8], polar=True)
       ax.set_theta_zero_location('N')
       ax.set_theta_direction(-1)
       ax.plot(np.deg2rad(Az),90-El,'*')
       ax.set_yticks(range(0, 90+10, 30))                   # Define the yticks
       yLabel = ['90', '60','30','0']
       ax.set_yticklabels(yLabel)
       ax.set_xticks(np.arange(0, np.pi*2, np.pi/2))        # Define the xticks
       xLabel = ['N' , 'E','S','W']
       ax.set_xticklabels(xLabel)
       # plt.text(-0.9,0.5,imagefile, horizontalalignment='center', verticalalignment='center', transform=ax.transAxes,fontsize=100)
       plt.title(imagefile)
    #    plt.show()
#    plt.savefig( options.outdir + "/" + imagefile, format = options.image_format, dpi = fig.dpi)
       plt.savefig( options.outdir + "/" + imagefile , format = options.image_format, dpi = options.dpi )
    else :
       print("File %s already exists -> skipped" % (outfile))

def mkdir_p(path):
   try:
      os.makedirs(path)
   except OSError as exc: # Python >2.5
      if exc.errno == errno.EEXIST:
         pass

def parse_options(idx=0):
   usage="Usage: %prog [options]\n"
   usage+='\tPlotting candidates\n'
   parser = OptionParser(usage=usage,version=1.00)

   parser.add_option('--all',action="store_true",dest="all",default=False, help="Create all images (even without candidates) [default %s]")
   parser.add_option('--dpi',dest="dpi",default=100, help="Image DPI [default %default]",type="int") # 25
   parser.add_option('--out_format','--out_type','--ext','--out_image_type',dest="image_format",default="jpg", help="Output image type [default %default]")
   parser.add_option('--outdir','--out_dir','--output_dir','--dir',dest="outdir",default="images/",help="Output directory [default %default]")
   # parser.add_option('--list_high_freq',dest="list_high_freq",default="cand_list_aavs2",help="High frequency candidates list [default %default]")
   # parser.add_option('--list_low_freq',dest="list_low_freq",default="cand_list_eda2",help="Low frequency candidates list [default %default]")

   (options, args) = parser.parse_args(sys.argv[idx:])
   mkdir_p( options.outdir )

   return (options, args)


if __name__ == '__main__':
   (options, args) = parse_options()

   listfile="fits_list_I_diff"
#   filename="chan_204_20220914T004101_I_diff_cand.txt"
   if len(sys.argv) > 1:   
      listfile = sys.argv[1]



   print("######################################################")
   print("PARAMETERS :")  
   print("######################################################")
   print("List file = %s" % (listfile))
   print("Outdir   = %s" % (options.outdir))   
   print("######################################################")

   print("Read filenames from list file %s:" % (listfile))
   fits_file_list = read_list_file( listfile )
   for fitsfile in fits_file_list :
      gc.collect() # explicit invokation of garbage collector to clean-up memory (otherwise uses memory like crazy!)
                   # see : https://stackoverflow.com/questions/1316767/how-can-i-explicitly-free-memory-in-python
      candfile=fitsfile.replace(".fits","_cand.txt")
      imagefile=fitsfile.replace(".fits","_cand.jpg")
      print("%s -> %s" % (fitsfile,candfile))   
      candidates=eda2_aavs2_concidence.read_candidate_file( candfile )
      
      Az=[]
      El=[]
      if (candidates is not None and len(candidates) > 0) or options.all :
         for cand in candidates :
            Az.append(cand.azim_deg)
            El.append(cand.elev_deg)
      
                  
         Az= np.array(Az)
         El= np.array(El)

         generate_plot(Az,El,options=options,imagefile=imagefile)   
         candidates=None         
         gc.collect()
      else :
         print("\tNo candidates in %s -> ignored" % (candfile))
#      sys.exit(0)
         
      
#   sys.exit(0)   

   # FITSNAME X Y FLUX[Jy] SNR ThreshInSigma RMS RA[deg] DEC[deg] AZIM[deg] ELEV[deg] UXTIME IMAGE_MIN IMAGE_MAX
   # chan_204_20220914T004101_I_diff.fits 28 117 117.47 74.97 5.00 1.57 171.061511 3.552535 66.890791 31.935454 1663116061.00 -12.5540 117.4658
   # Az=[90, 180, 270,]
   # El=[20, 30, 10]
#   Az=[66.890791]
#   El=[31.935454]
#   Az= np.array(Az)
#   El= np.array(El)
#   generate_plot(Az,El,options)

