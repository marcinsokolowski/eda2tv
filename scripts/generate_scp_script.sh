#!/bin/bash

# lc_file=S1832-0911_diff_max.txt
lc_file=S1832-0911_diff.txt
if [[ -n "$1" && "$1" != "-" ]]; then
   lc_file="$1"
fi

awk '{if($1!="#"){if($3>200 && $8<60){file=$9;;print "rsync -avP eda2:/data//2024_07_29_ch294_corr/merged/"$file" .";}}}' ${lc_file}

echo "List of candidates:"
awk '{if($1!="#"){if($3>200 && $8<60){print $0;}}}' ${lc_file}
# awk '{if($2>200){if($1!="#"){utc=strftime("%Y%m%dT%H%M",$1,1);print "rsync -avP eda2:/data//2024_07_29_ch294_corr/merged/*"utc"*.fits .";}}}' ${lc_file}
