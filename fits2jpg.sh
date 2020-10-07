#!/bin/bash

postfix="_XX"
if [[ -n "$1" && "$1" != "-" ]]; then
   postfix=$1
fi


ls *${postfix}.fits > list${postfix}

echo "python ~/github/eda2tv/imagefits.py list${postfix} --outdir images_${postfix} --ext=png --fits_list=list${postfix} --out_image_type="png" --every_n_fits=1"
python ~/github/eda2tv/imagefits.py list${postfix} --outdir images_${postfix} --ext=png --fits_list=list${postfix} --out_image_type="png" --every_n_fits=1