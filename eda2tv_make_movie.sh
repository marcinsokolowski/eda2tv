#!/bin/bash

freq_ch=204
if [[ -n "$1" && "$1" != "-" ]]; then
   freq_ch=$1
fi

station_name="eda2"
if [[ -n "$2" && "$2" != "-" ]]; then
   station_name=$2
fi

movie_png_rate=1
if [[ -n "$3" && "$3" != "-" ]]; then
   movie_png_rate=$3
fi

mkdir -p images/movie/
cd images/movie/

echo "eda2tv_make_movie.sh started at :"
date


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

echo "eda2tv_make_movie.sh finished at :"
date
