


def beamcorrXY2I( lc_filename_x, lc_filename_y, outfile_lc_i ) :
   lc_x = read_beam_corr_lc( lc_filename_x )   
   lc_y = read_beam_corr_lc( lc_filename_y )   

   lc_i = xy2i( lc_x, lc_y )

   # save to file :
