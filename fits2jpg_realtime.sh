#!/bin/bash

prefix=eda2_allsky_image

postfix=_real

listfile=${prefix}${postfix}.list

station_name=eda2

echo "ls ${prefix}_????????_??????${postfix}.fits  > ${listfile}"
ls ${prefix}_????????_??????${postfix}.fits  > ${listfile}


echo "python ~/Software/eda2tv/imagefits.py ${listfile} --outdir images/ --ext=png --fits_list=${listfile} --out_image_type=png --every_n_fits=1"
python ~/Software/eda2tv/imagefits.py ${listfile} --outdir images/ --ext=png --fits_list=${listfile} --out_image_type=png --every_n_fits=1


