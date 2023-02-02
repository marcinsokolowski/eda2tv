#!/bin/bash

export PATH=~/Software/eda2tv/source_finder/:$PATH

path=`which dump_pixel_radec.py`


echo "monitor_source_radec.sh 139.52374995 -12.09555556 HYDRAA_raw  fits_list_I \"--use_weighting\""
monitor_source_radec.sh 139.52374995 -12.09555556 HYDRAA_raw  fits_list_I "--use_weighting"


echo "monitor_source_radec.sh 187.70591667 12.39112222 VIRGOA_raw fits_list_I \"--use_weighting\""
monitor_source_radec.sh 187.70591667 12.39112222 VIRGOA_raw fits_list_I "--use_weighting"

echo "monitor_source_radec.sh 333.6072499500 -17.02661111 3C444_raw fits_list_I \"--use_weighting\""
monitor_source_radec.sh 333.6072499500 -17.02661111 3C444_raw fits_list_I "--use_weighting"


