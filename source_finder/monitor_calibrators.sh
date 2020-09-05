#!/bin/bash

export PATH=~/Software/eda2tv/source_finder/:$PATH

path=`which dump_pixel_radec.py`


echo "monitor_source_radec.sh 139.52374995 -12.09555556 HYDRAA  fits_list_I \"--use_weighting --bkg\""
monitor_source_radec.sh 139.52374995 -12.09555556 HYDRAA  fits_list_I "--use_weighting --bkg"


echo "monitor_source_radec.sh 187.70591667 12.39112222 VIRGOA fits_list_I \"--use_weighting --bkg\""
monitor_source_radec.sh 187.70591667 12.39112222 VIRGOA fits_list_I "--use_weighting --bkg"

echo "monitor_source_radec.sh 333.6072499500 -17.02661111 3C444 fits_list_I \"--use_weighting --bkg\""
monitor_source_radec.sh 333.6072499500 -17.02661111 3C444 fits_list_I "--use_weighting --bkg"


