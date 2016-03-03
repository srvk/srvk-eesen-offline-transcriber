#!/bin/bash
#
# mkpages.sh - script to create web pages from a folder (beneath the /vagrant/www directory)
#              containing videos named "public" with subfolders "video" and subtitles "sub"

# Format of videos folder:  has name 
webroot=/vagrant/www

cat $webroot/snips/head.snip > $webroot/index.html

# iterate over videos

for f in `ls $webroot/video/*.mp4`; do

  filename=$(basename $f)
  extension="${filename##*.}"
  fn="${filename%.*}"

  echo "processing video" $fn

  # create thumbnail - grab frame at the 1 minute mark
  avconv -y -i $webroot/video/$fn.mp4 -ss 00:00:57.000 -vframes 1 $webroot/thumbs/$fn.png 2>/dev/null
  if [ ! -f $webroot/thumbs/$fn.png ]; # try 1 second mark
     then 
     avconv -y -i $webroot/video/$fn.mp4 -ss 00:00:01.000 -vframes 1 $webroot/thumbs/$fn.png 2>/dev/null
  fi
  # final try - give up, use dummy thumbnail image
  if [ ! -f $webroot/thumbs/$fn.png ];
     then 
     cp $webroot/img/video-generic.png $webroot/thumbs/$fn.png
  fi


  # 
  # create VTT subtitle files from SRT (transcribed) format
#  bash srt2vtt.sh $webroot/sub/$fn.srt
#  mv $fn.vtt $webroot/sub/
  echo -e "WEBVTT\n" >$webroot/sub/$fn.vtt
  cat $webroot/sub/$fn.srt >>$webroot/sub/$fn.vtt
  sed -i s/','/'.'/g $webroot/sub/$fn.vtt


  # create video page
  sed s/__VIDEONAME__/$fn/g $webroot/snips/play-template.html > $webroot/play$fn.html

  # Add video links to list in public/index.html
  cat >> $webroot/index.html <<EOF

            <div class="col-sm-4">
                <div class="video-post v-col-3 wr-video">
                <img src="thumbs/$fn.png" alt="" class="img-responsive"/>
                <a href="play$fn.html"><span class="vd-button"></span></a>
                <h2>Video: $filename </h2>
                </div>
            </div>
EOF


done

cat $webroot/snips/foot.snip >> $webroot/index.html
