
# import pdb

import astropy.io.fits as pyfits
import numpy
import sys
import math

def get_background( data, xc_float , yc_float, r0=4, r1=6 ) :

   xc = int( round(xc_float) )
   yc = int( round(yc_float) )

   values = []
   for y in range(yc-r1,yc+r1+1) :
      for x in range(xc-r1,xc+r1+1) :
         dist = math.sqrt( (y-yc)**2 + (x-xc)**2 )
         
         if dist >= r0 and dist <= r1 :
            if x>=0 and x<data.shape[0] and y>=0 and y<=data.shape[1] :
               values.append( data[y,x] )
            
   values.sort()
   
   bkg = 0   
   l = len(values)
   if l > 0 :
      bkg = values[int(l/2)]
   
   return bkg         

def get_weighted_pixel_value( data, xc , yc ) :
   print("get_weighted_pixel_value( %.2f , %.2f)" % (xc,yc))

   pix = numpy.array( [xc,yc] )
   pixel_size = numpy.array( [1,1] )

   xc_int = int( round(xc) )
   yc_int = int( round(yc) )
      
   for y in range(yc_int+2+1,yc_int-2,-1) :
      line = "";
      for x in range(xc_int-2,xc_int+2,1) :
          val = data[y,x]
#          line += ( " %05.2f " % (val))
          line += ( " (%d,%d)=%.2f " % (x,y,val))
      
      print(line + "\n")
  
   left_bottom  = pix + numpy.array( [-1, -1] )*0.5
   right_bottom = pix + numpy.array( [+1, -1] )*0.5
   left_top     = pix + numpy.array( [-1, +1] )*0.5
   right_top    = pix + numpy.array( [+1, +1] )*0.5


   v1 = 0.00
   v2 = 0.00
   v3 = 0.00
   v4 = 0.00   
   
   left_bottom_corner   = numpy.floor(left_bottom)  + numpy.array( [1,1] )
   diff                 = ( left_bottom_corner - left_bottom )   
   w_left_bottom_corner = math.fabs( diff[0]*diff[1] )
   val1                 = data[ int(numpy.floor(left_bottom)[1]) , int(numpy.floor(left_bottom)[0]) ]
   v1                   = val1 * w_left_bottom_corner
   print("LEFT-BOTTOM  : (%.4f,%.4f) - (%d,%d) = (%.2f,%.2f) -> value * w_lb = %.4f * %.4f = %.4f" % (left_bottom[0],left_bottom[1],left_bottom_corner[0],left_bottom_corner[1],diff[0],diff[1],val1,w_left_bottom_corner,v1))
   
   right_bottom_corner = numpy.floor(right_bottom) + numpy.array( [0,1] )
   diff                 = ( right_bottom_corner - right_bottom )
   w_right_bottom_corner = math.fabs( diff[0]*diff[1] )
   val2                 = data[ int(numpy.floor(right_bottom)[1]) , int(numpy.floor(right_bottom)[0]) ]
   v2                   = val2 * w_right_bottom_corner
   print("RIGHT-BOTTOM : (%.4f,%.4f) - (%d,%d) = (%.2f,%.2f) -> value * w_lb = %.4f * %.4f = %.4f" % (right_bottom[0],right_bottom[1],right_bottom_corner[0],right_bottom_corner[1],diff[0],diff[1],val2,w_right_bottom_corner,v2))
   
   left_top_corner     = numpy.floor(left_top)     + numpy.array( [1,0] )
   diff                = ( left_top_corner - left_top )
   w_left_top_corner   = math.fabs( diff[0]*diff[1] )
   val3                 = data[ int(numpy.floor(left_top)[1]) , int(numpy.floor(left_top)[0]) ]
   v3                   = val3 * w_left_top_corner
   print("LEFT-TOP     : (%.4f,%.4f) - (%d,%d) = (%.2f,%.2f) -> value * w_lb = %.4f * %.4f = %.4f" % (left_top[0],left_top[1],left_top_corner[0],left_top_corner[1],diff[0],diff[1],val3,w_left_top_corner,v3))

   
   right_top_corner    = numpy.floor(right_top)    
   diff                = ( right_top_corner - right_top )
   w_right_top_corner  = math.fabs( diff[0]*diff[1] )
   val4                = data[ int(numpy.floor(right_top)[1]) , int(numpy.floor(right_top)[0]) ]
   v4                   = val4 * w_right_top_corner
   print("RIGHT-TOP    : (%.4f,%.4f) - (%d,%d) = (%.2f,%.2f) -> value * w_lb = %.4f * %.4f = %.4f" % (right_top[0],right_top[1],right_top_corner[0],right_top_corner[1],diff[0],diff[1],val4,w_right_top_corner,v4))
   
   
   
#   if left_bottom_corner[0] >= 0 and left_bottom_corner[1] >= 0 and left_bottom_corner[0] < data.shape[0] and left_bottom_corner[1] < data.shape[1] :
#      print("v1 := %.8f * %.8f" % (data[ int(left_bottom_corner[1])  , int(left_bottom_corner[0]) ],w_right_bottom_corner))
#       
#   if right_bottom_corner[0] >= 0 and right_bottom_corner[1] >=0 and right_bottom_corner[0] < data.shape[0] and right_bottom_corner[1] < data.shape[1] :
#      
#   if left_top_corner[0] >= 0 and left_top_corner[1] >= 0 and left_top_corner[0] < data.shape[0] and left_top_corner[1] < data.shape[1] :
#      v3 = data[ int(left_top_corner[1])     , int(left_top_corner[0]) ]*w_left_top_corner
#      
#   if right_top_corner[0] >=0 and right_top_corner[1] >=0 and right_top_corner[0] < data.shape[0] and right_top_corner[1] < data.shape[1] :   
#      v4 = data[ int(right_top_corner[1])    , int(right_top_corner[0]) ]*w_right_top_corner
      
   weighted_sum = v1 + v2 + v3 + v4
   
   print("Returning %.4f = %.4f + %.4f + %.4f + %.4f" % (weighted_sum,v1,v2,v3,v4))   
                  
                  
   return (weighted_sum,v1,v2,v3,v4)  

if __name__ == '__main__':
   
   if len(sys.argv) > 1:
       fitsname = sys.argv[1]
   
   x = 0
   if len(sys.argv) > 2:
       x = float( sys.argv[2] )
   
   y = 0   
   if len(sys.argv) > 3:
       y = float( sys.argv[3] )
   
   fits = pyfits.open(fitsname)
   data = fits[0].data[0][0]      
   
#   x = 2 
#   y = 2
   (weighted_sum,v1,v2,v3,v4) = get_weighted_pixel_value(data, x, y )
   print("Weighted value = %.4f" % (weighted_sum))
   
   