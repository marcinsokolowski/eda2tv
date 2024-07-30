#!/bin/bash

cat chan*_I_diff_cand.txt | grep -v "# " | awk '{print $8" "$9;}' > radec.txt

mkdir -p images/
root -b -q -l "transientplot_radec_data_and_tle.C(\"radec.txt\")"
