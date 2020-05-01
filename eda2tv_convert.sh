#!/bin/bash

freq_ch=204
if [[ -n "$1" && "$1" != "-" ]]; then
   freq_ch=$1
fi

voltages=1
if [[ -n "$2" && "$2" != "-" ]]; then
   voltages=$2
fi

process_all=0
if [[ -n "$3" && "$3" != "-" ]]; then
   process_all=$3
fi

# typical inttime=0.2831 seconds and number of integrations 8140  -i 0.2831 -n 8140 now for sensitivity we should have 2 timesteps in a single uvfits :
inttime=0.2831 # sensitivity 0.14
if [[ -n "$4" && "$4" != "-" ]]; then
   inttime=$4
fi

n_avg=8140 # sensitivity 4096 or 4070
if [[ -n "$5" && "$5" != "-" ]]; then
   n_avg=$5
fi

station_name=eda2
if [[ -n "$6" && "$6" != "-" ]]; then
   station_name=$6
fi

use_full_files=0
if [[ -n "$7" && "$7" != "-" ]]; then
   use_full_files=$7
fi

imsize=180 # 128 or 256 
if [[ $freq_ch -gt 204 ]]; then
   imsize=360
else
   if [[ $freq_ch -lt 141 ]]; then
      imsize=120
      if [[ $freq_ch -lt 80 ]]; then
         imsize=60
      fi
   fi
fi
if [[ -n "$8" && "$8" != "-" ]]; then
   imsize=$8
fi

convert_options=""
if [[ -n "$9" && "$9" != "-" ]]; then
   convert_options="$9"
fi

movie_png_rate=1 # every fits file is converted to png and movie
if [[ -n "${10}" && "${10}" != "-" ]]; then
   movie_png_rate=${10}
fi

reprocess_all=0
if [[ -n "${11}" && "${11}" != "-" ]]; then
   reprocess_all=${11}
fi

publish=1
if [[ -n "${12}" && "${12}" != "-" ]]; then
   publish=${12}
fi

echo "##################################"
echo "PARAMETERS:"
echo "##################################"
echo "ch      = $freq_ch"
echo "imsize  = $imsize"
echo "publish = $publish"
echo "##################################"



# temporary :
export PATH=./:$PATH
www_dir=

# merged newly collected HDF5 files:
pwd
mkdir -p merged/

if [[ $voltages -gt 0 ]]; then
   echo "merge_last_hdf5_file.sh 1 0"
   merge_last_hdf5_file.sh 1 0
   echo "merge finished at:"
   date

   # use diff to get a list of newly merged HDF5 files :
   cd merged

   # update a list of merged HDF5 files :
   echo "ls *.hdf5 > merged_hdf5_list.txt"
   ls *.hdf5 > merged_hdf5_list.txt

   touch processed.txt


   pwd
   date
   touch merged_hdf5_list.last_processed
   diff merged_hdf5_list.txt merged_hdf5_list.last_processed | awk '{if($1=="<"){print $2;}}' > new_merged_hdf5_list.txt
else
   if [[ $use_full_files -gt 0 ]]; then      
      count=`ls -tr correlation_burst_*hdf5 | wc -l`
      if [[ $count -ge 2 ]]; then
         last_corr_file=`ls -tr correlation_burst_*hdf5 | tail -2 | head -1` 
         echo "Last correlated file = $last_corr_file"

         # TODO - change for making a copy of the last 30 seconds (see my plan)   
         cd merged/


         echo "INFO : Using full HDF5 files (requires option --max_file_size_gb to be set to maximum a few minutes of acquisition"
         echo $last_corr_file > new_merged_hdf5_list.txt
         ln -s ../${last_corr_file}
         pwd
         date
      else
         echo "WARNING : only $count files collected -> ignored for now"
         exit;
      fi
   else
      last_corr_file=`ls -tr correlation_burst_*hdf5 | tail -1`
      echo "Last correlated file = $last_corr_file"

      # TODO - change for making a copy of the last 30 seconds (see my plan)   
      cd merged/
   
      echo "INFO : using new / experimental mode to image last 30 seconds of the correlated HDF5 file"
      rsync -avP ../$last_corr_file latest_hdf5_file.hdf5
      
      
      echo "rm -f last_N_integrations.hdf5"
      rm -f last_N_integrations.hdf5
      
      while [[ ! -s last_N_integrations.hdf5 ]]; 
      do
         # get last 30 seconds of data:           
         echo "python $AAVS_HOME/hdf5_correlator/scripts/get_hdf5_part.py latest_hdf5_file.hdf5 last_N_integrations.hdf5 --n_integrations=5"
         python $AAVS_HOME/hdf5_correlator/scripts/get_hdf5_part.py latest_hdf5_file.hdf5 last_N_integrations.hdf5 --n_integrations=5
         date
      done
      
      # in this case we just process the latest file so no need to check if already procssed :
      echo "rm -f processed.txt"
      rm -f processed.txt
      touch processed.txt # create an empty file

      # force - re-processing the same hdf5 file:
      convert_options="$convert_options -F"
      
      ls last_N_integrations.hdf5 > merged_hdf5_list.txt
      cp merged_hdf5_list.txt new_merged_hdf5_list.txt
      pwd
      date
      touch merged_hdf5_list.last_processed
   fi
fi 
input_file=new_merged_hdf5_list.txt  

if [[ $reprocess_all -gt 0 ]]; then
   echo "INFO : requested to re-process all"
   rm -f new_merged_hdf5_list.txt
   
   for hdf5file in `ls -tr ../*.hdf5`
   do
      echo "ln -s ${hdf5file}"
      ln -s ${hdf5file}
      
      bname=`basename ${hdf5file}`

      echo "echo $bname >> new_merged_hdf5_list.txt"
      echo $bname >> new_merged_hdf5_list.txt
   done   
fi

n_new_processed=0
# hdf5_to_uvfits_all.sh -c -l -i 0.2831 -n 8140 -d "./" -N -z -f 126 -l -L new_hdf5_list.txt
for line in `cat $input_file`
do
   count=`grep "$line" processed.txt | wc -l`
   
   if [[ $count -le 0 ]]; then
      echo
      date
      echo $line > new_hdf5_list.txt   

      if [[ $voltages -gt 0 ]]; then
         echo "Processing merged voltages ..."
         cat new_hdf5_list.txt
         echo "hdf5_to_uvfits_all.sh -c -l -i $inttime -n $n_avg -d \"./\" -N -z -f $freq_ch -l -L new_hdf5_list.txt -s ${station_name} $convert_options"   
         hdf5_to_uvfits_all.sh -c -l -i $inttime -n $n_avg -d "./" -N -z -f $freq_ch -l -L new_hdf5_list.txt -s ${station_name} $convert_options
         
         ls *.uvfits > uvfits_list

         n_new_processed=$(($n_new_processed+1))
      else 
         echo "Processing last correlated file ..."
         cat new_hdf5_list.txt
         
         # -S 0 : turns off conversion to CASA .ms
         echo "hdf5_to_uvfits_all.sh -c -l -i $inttime -n $n_avg -d "./" -N -z -a 1 -f $freq_ch -L new_hdf5_list.txt -S 0 -s ${station_name} $convert_options"
         hdf5_to_uvfits_all.sh -c -l -i $inttime -n $n_avg -d "./" -N -z -a 1 -f $freq_ch -L new_hdf5_list.txt -S 0 -s ${station_name} $convert_options
         
         if [[ $process_all -le 0 ]]; then
            ls *.uvfits > uvfits_list
         else
            if [[ $process_all -le 1 ]]; then
               ls *.uvfits | tail -2 > uvfits_list
            else
               ls *.uvfits | awk -v m=${process_all} '{if((NR % m)==0){print $0;}}' > uvfits_list
            fi
         fi
         
         n_new_processed=$(($n_new_processed+1))
      fi

    
      echo "miriad_applycal_and_image_list.sh uvfits_list chan_${freq_ch} ${imsize}"
      miriad_applycal_and_image_list.sh uvfits_list chan_${freq_ch} ${imsize}

      prev_path=`pwd`
      cd images/
      last_image=`ls -tr *.png | tail -1`
      echo "Last image = $last_image"
   
      echo "scp $last_image aavs1-server:/exports/eda/${station_name}/tv/sky.png"
      scp $last_image aavs1-server:/exports/eda/${station_name}/tv/sky.png              
 
      cd $prev_path

      echo $line >> processed.txt      
#   else
#      echo "File $line already processed"
   fi
done

# update list of last processed file 
echo "cp merged_hdf5_list.txt merged_hdf5_list.last_processed"
cp merged_hdf5_list.txt merged_hdf5_list.last_processed

mkdir -p images/movie/

if [[ $n_new_processed -gt 0 ]]; then
   cd images/movie/

   i=0
   for png in `ls ../chan*png`; 
   do      
      if [[ $(($i % $movie_png_rate)) == 0 ]]; then
         out_i=$(($i / $movie_png_rate))
         i_str=`echo $out_i | awk '{printf("%06d\n",$1);}'`;    
         ln -s ${png} chan_${freq_ch}_XX_${i_str}.png; 
      fi
      i=$(($i+1));
   done      

   #      mencoder mf://*.png -mf w=800:h=600:fps=10:type=png -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell -oac copy -o 20200226_eda2.mpg
   #      mencoder mf://*.png -mf w=800:h=600:fps=10:type=png -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell -oac copy -o 20200226_eda2.avi      
   echo "rm -f sky_last_24h.mp4"
   rm -f sky_last_24h.mp4
   echo "ffmpeg -framerate 25 -i chan_${freq_ch}_XX_%6d.png -c:v libx264 -vf \"drawtext=fontfile=/usr/share/fonts/truetype/freefont/FreeSans.ttf:text=%{n}:x=(w-tw)/2:y=h-(2*lh): fontcolor=white:box=1:boxcolor=0x00000099\" -pix_fmt yuv420p sky_last_24h.mp4"
   ffmpeg -framerate 25 -i chan_${freq_ch}_XX_%6d.png -c:v libx264 -vf "drawtext=fontfile=/usr/share/fonts/truetype/freefont/FreeSans.ttf:text=%{n}:x=(w-tw)/2:y=h-(2*lh): fontcolor=white:box=1:boxcolor=0x00000099" -pix_fmt yuv420p sky_last_24h.mp4

   echo $freq_ch > channel.txt

   echo "scp sky_last_24h.mp4 aavs1-server:/exports/eda/${station_name}/tv/"
   scp sky_last_24h.mp4 aavs1-server:/exports/eda/${station_name}/tv/

   echo "scp channel.txt aavs1-server:/exports/eda/${station_name}/tv/"
   scp channel.txt aavs1-server:/exports/eda/${station_name}/tv/
   cd ../../
else
   echo "WARNING : no new files processed -> nothing to copy to www server"
fi   

echo "eda2tv_convert.sh finished at :"
date
