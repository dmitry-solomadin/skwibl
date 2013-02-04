#!/bin/bash

echo "cleaning"

find ./ -name \*~ -delete
rm -f *.js
find ./assets -name "*.js" -delete
find ./config -name "*.js" -delete
find ./controllers -name "*.js" -delete
find ./db -name "*.js" -delete
find ./helpers -name "*.js" -delete
find ./routes -name "*.js" -delete
find ./setup -name "*.js" -delete
find ./smtp -name "*.js" -delete
find ./sockets -name "*.js" -delete
find ./tools -name "*.js" -delete
rm -f ./vendor/js/skwibl.js ./vendor/js/skwibl.min.js ./vendor/js/skwibl.min.js.gz
rm -f ./vendor/js/Jplayer.swf
rm -f ./vendor/css/skwibl.css ./vendor/css/skwibl-min.css ./vendor/css/skwibl-min.css.gz
