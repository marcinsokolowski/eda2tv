#!/bin/bash

start_ux=`date +%s`
date

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

process_last_hdf5_file=0
if [[ -n "${13}" && "${13}" != "-" ]]; then
   process_last_hdf5_file=${13}
fi


echo "##################################"
echo "PARAMETERS:"
echo "##################################"
echo "ch      = $freq_ch"
echo "imsize  = $imsize"
echo "publish = $publish"
echo "process_last_hdf5_file = $process_last_hdf5_file"
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
# WARNING : for now assuming not so many HDF5 files will be produced :   
   echo "ls *.hdf5 > merged_hdf5_list.txt"
   ls *.hdf5 > merged_hdf5_list.txt
#   echo "find .  -maxdepth 1  -name \"*.hdf5\" | awk '{print substr($1,3);}' > merged_hdf5_list.txt"
#   find .  -maxdepth 1  -name "*.hdf5" | awk '{print substr($1,3);}' > merged_hdf5_list.txt

   touch processed.txt


   pwd
   date
   touch merged_hdf5_list.last_processed
   diff merged_hdf5_list.txt merged_hdf5_list.last_processed | awk '{if($1=="<"){print $2;}}' > new_merged_hdf5_list.txt
else
   # workaround correlation_burst_204_20200530_23500_1.hdf5 - no %05d.hdf5 !!!
   rm -f tmp_correlation_files_list.txt
   i=0
   found=1
   while [[ 1 ]]; 
   do
      hdf5file=`ls correlation_burst_*_${i}.hdf5 | tail -1`
      if [[ -s $hdf5file ]]; then
         echo $hdf5file >> tmp_correlation_files_list.txt
      else
         echo "File $hdf5file does not exist -> exiting loop"
         break
      fi
      i=$(($i+1))
   done


   if [[ $use_full_files -gt 0 ]]; then      
      count=`ls -tr correlation_burst_*hdf5 | wc -l`      
      
      if [[ $count -ge 2 ]]; then
         last_corr_file=`cat tmp_correlation_files_list.txt | tail -2 | head -1` 
         echo "Last correlated file = $last_corr_file"

         # TODO - change for making a copy of the last 30 seconds (see my plan)   
         cd merged/


         if [[ $process_last_hdf5_file -gt 0 ]]; then
            # re-process just the latest HDF5 file
            echo "INFO : Using full HDF5 files (requires option --max_file_size_gb to be set to maximum a few minutes of acquisition"
            echo $last_corr_file > new_merged_hdf5_list.txt
            ln -s ../${last_corr_file}
         else         
            # re-process all not processed yet :
            echo "rm -f new_merged_hdf5_list.txt"
            rm -f new_merged_hdf5_list.txt
            
            for hdf5file_full_path in `cat ../tmp_correlation_files_list.txt`
            do
               hdf5file=`basename ${hdf5file_full_path}`
               
               if [[ ! -s ${hdf5file} ]]; then
                  echo "ln -s ../${hdf5file}"
                  ln -s ../${hdf5file}
                  
                  echo ${hdf5file} >> new_merged_hdf5_list.txt
                  echo "PROGRESS : added ${hdf5file} file for processing ..."
               else
                  echo "INFO : line ${hdf5file} already exists -> skipped"
               fi
               
               if [[ $hdf5file == $last_corr_file ]]; then
                  echo "Last full HDF5 file is $last_corr_file -> no more links created -> exiting loop"
                  break
               else
                  echo "Created link to ../${hdf5file} for processing"
               fi
            done
         fi
         pwd
         date
      else
         echo "WARNING : only $count files collected -> ignored for now"
         exit;
      fi
   else
      last_corr_file=`cat tmp_correlation_files_list.txt | tail -1`
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
#   for hdf5file in `find .  -maxdepth 1  -name "*.hdf5" | awk '{print substr($1,3);}' > merged_hdf5_list.txt`
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
         
#         ls *.uvfits > uvfits_list
         echo "find .  -maxdepth 1  -name \"*.uvfits\" | awk '{print substr($1,3);}' | sort > uvfits_list"
         find .  -maxdepth 1  -name "*.uvfits" | awk '{print substr($1,3);}'  | sort > uvfits_list

         n_new_processed=$(($n_new_processed+1))
      else 
         echo "Processing last correlated file ..."
         cat new_hdf5_list.txt
         
         # -S 0 : turns off conversion to CASA .ms
         echo "hdf5_to_uvfits_all.sh -c -l -i $inttime -n $n_avg -d "./" -N -z -a 1 -f $freq_ch -L new_hdf5_list.txt -S 0 -s ${station_name} $convert_options"
         hdf5_to_uvfits_all.sh -c -l -i $inttime -n $n_avg -d "./" -N -z -a 1 -f $freq_ch -L new_hdf5_list.txt -S 0 -s ${station_name} $convert_options
         
         if [[ $process_all -le 0 ]]; then
#            ls *.uvfits > uvfits_list
             echo "find .  -maxdepth 1  -name \"*.uvfits\" | awk '{print substr($1,3);}' | sort > uvfits_list"
             find .  -maxdepth 1  -name "*.uvfits" | awk '{print substr($1,3);}' | sort > uvfits_list
         else
            if [[ $process_all -le 1 ]]; then
#               ls *.uvfits | tail -2 > uvfits_list
               find .  -maxdepth 1  -name "*.uvfits" | awk '{print substr($1,3);}' | sort | tail -2 > uvfits_list
            else
#               ls *.uvfits | awk -v m=${process_all} '{if((NR % m)==0){print $0;}}' > uvfits_list
               find .  -maxdepth 1  -name "*.uvfits" | awk '{print substr($1,3);}' | sort | awk -v m=${process_all} '{if((NR % m)==0){print $0;}}' > uvfits_list
            fi
         fi
         
         n_new_processed=$(($n_new_processed+1))
      fi
    
      # also does (XX+YY) -> I :
      # convert every ${movie_png_rate} image to png 
      echo "miriad_applycal_and_image_list.sh uvfits_list chan_${freq_ch} ${imsize} - 0 ${movie_png_rate}"
      miriad_applycal_and_image_list.sh uvfits_list chan_${freq_ch} ${imsize} - 0 ${movie_png_rate}
      
      prev_path=`pwd`
      cd images/
      last_image=`ls -tr *.png | tail -1`
# WARNING : how to do -tr with find ???      
#      last_image=`find .  -maxdepth 1  -name "*.uvfits" | awk '{print substr($1,3);}' 
      echo "Last image = $last_image"
   
      if [[ $publish -gt 0 ]]; then
         echo "scp $last_image aavs1-server:/exports/eda/${station_name}/tv/sky.png"
         scp $last_image aavs1-server:/exports/eda/${station_name}/tv/sky.png              
      else
         echo "WARNING : publishing of results on the WWW server is not required"         
      fi
 
      cd $prev_path

      echo $line >> processed.txt      
      
      echo "PROFILER : hdf5 file processing finished at :"
      date
#   else
#      echo "File $line already processed"
   fi
done

# update list of last processed file 
echo "cp merged_hdf5_list.txt merged_hdf5_list.last_processed"
cp merged_hdf5_list.txt merged_hdf5_list.last_processed

if [[ $n_new_processed -gt 0 ]]; then
   echo "eda2tv_make_movie.sh ${freq_ch} ${station_name}" # ${movie_png_rate}"
   eda2tv_make_movie.sh ${freq_ch} ${station_name} # ${movie_png_rate} not used here, but at level of conversion from FITS to jpg 
else
   echo "WARNING : no new files processed -> nothing to copy to www server"
fi   

echo "eda2tv_convert.sh finished at :"
date
end_ux=`date +%s`
took=$(($start_ux-$end_ux))
echo "eda2tv_convert.sh took $took [seconds]"
