#!/bin/bash

export PATH=~/Software/eda2tv/source_finder/:$PATH

path=`which dump_pixel_radec.py`


echo "monitor_source_radec.sh 139.52374995 -12.09555556 HYDRAA_medianbkg  fits_list_I \"--use_weighting --bkg=4 --median_bkg\""
monitor_source_radec.sh 139.52374995 -12.09555556 HYDRAA_medianbkg  fits_list_I "--use_weighting --bkg=4 --median_bkg"


echo "monitor_source_radec.sh 187.70591667 12.39112222 VIRGOA_medianbkg fits_list_I \"--use_weighting --bkg=4 --median_bkg\""
monitor_source_radec.sh 187.70591667 12.39112222 VIRGOA_medianbkg fits_list_I "--use_weighting --bkg=4 --median_bkg"

echo "monitor_source_radec.sh 333.6072499500 -17.02661111 3C444_medianbkg fits_list_I \"--use_weighting --bkg=4 --median_bkg\""
monitor_source_radec.sh 333.6072499500 -17.02661111 3C444_medianbkg fits_list_I "--use_weighting --bkg=4 --median_bkg"


