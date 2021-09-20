# quidnunc

quidnunc :  a person who seeks to know all the latest news or gossip :  busybody
# ALSO: A PROJECT NOBODY IN THEIR RIGHT MIND SHOULD USE. IT'S ALL BASH FOR GOD'S SAKE!!!
# Seriously, go look at Quidnunc2, which is sane.


A gigantic mashup of technologies for eavesdropping on your neighbors...
Actually it's for stomping on your freedoms...
Or maybe it'll catch burglars. I dunno.

## Usage

# Introduction to quidnunc

TODO: write [great documentation](http://jacobian.org/writing/what-to-write/)

## Some useful ffmpeg commands I'll use...

### Grab from the IP cams reliably and stream to chunked files:

    ffmpeg -y -loglevel error -i "rtsp://USERGOES:WITHPASSWORD@1.2.3.4:554/videoMain" \
        -f dshow -vcodec copy  -acodec copy -tune zerolatency -vsync 1 -async 1 \
        -f segment  -segment_time 60 -segment_atclocktime 1 -map 0  \
        -fflags nobuffer -strftime 1 \
        "root/var/lib/quidnunc/videos/cam1-%Y-%m-%d_%H:%M:%S.mpg"
        
### Convert that file into a series of images (every 10 seconds...)

    ffmpeg -i ../../videos/cam1-2015-12-07_19:40:00.mpg \
        -vf select="eq(pict_type\,PICT_TYPE_I)" -r 0.1 \
        -q 10 cam1-img-%05d.jpg
        
### Then back to a tiny little jpg video

    ffmpeg -r 0.1 -start_number 1 -f image2 -i "cam1-img-%05d.jpg" 
        -vcodec mjpeg -qscale 1 video.avi
        
        
        
## Then the cool fswatch and lsof stuff to check if a file is free

### Is it currently being written?

    lsof -t  -- /path/to/cam1-2015-12-07_20:19:02.mpg
    
### fswatch to find what is changing:

    fswatch -x root/var/lib/quidnunc/videos
    
Which has a result format like:

    /absolute/path/to/quidnunc/root/var/lib/quidnunc/videos/cam1-2015-12-07_20:19:02.mpg Created IsFile
    
## License

Copyright © 2015 FIXME

Distributed under the Eclipse Public License either version 1.0 or (at
your option) any later version.
