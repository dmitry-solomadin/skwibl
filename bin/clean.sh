#!/bin/bash

echo "cleaning"

find ./ -name \*~ -delete
rm -f *.js
find ./client -name "*.js" -delete
find ./config -name "*.js" -delete
find ./controllers -name "*.js" -delete
find ./db -name "*.js" -delete
find ./helpers -name "*.js" -delete
find ./routes -name "*.js" -delete
find ./setup -name "*.js" -delete
find ./smtp -name "*.js" -delete
find ./sockets -name "*.js" -delete
find ./tools -name "*.js" -delete

STAMP=$1

rm -f ./assets/js/skwibl.js ./assets/js/skwibl$STAMP.min.js ./assets/js/skwibl$STAMP.min.js.gz
rm -f ./assets/js/Jplayer.swf
rm -f ./assets/css/skwibl.css ./assets/css/skwibl$STAMP-min.css ./assets/css/skwibl$STAMP-min.css.gz
