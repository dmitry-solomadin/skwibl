#!/bin/bash

. bin/config.sh

## list of js files
JS_LIST=`cat views/shared/application_scripts.ect | grep -o '\/js.*\.js' | sed 's/\/js/\.\/assets\/js/'`

## list of css files
CSS_LIST=`cat views/shared/application_scripts.ect | grep -o '\/css.*\.css' | sed 's/^/\.\/assets/'`

cat $SOCKETIO >> $JS_NAME.js
for SCRIPT in $JS_LIST; do
  if [[ $SCRIPT != *'/skwibl.min.js' ]]; then
    cat $SCRIPT >> $JS_NAME.js
  fi
done

STAMP=$1

$UGLIFYJS $JS_NAME.js -c -o $JS_NAME$STAMP.min.js
gzip -9 $JS_NAME$STAMP.min.js -c > $JS_NAME$STAMP.min.js.gz

rm -f $JS_NAME.js $JS_NAME$STAMP.min.js

cp ./assets/js/vendor/Jplayer.swf ./assets/js/Jplayer.swf

for CSS in $CSS_LIST; do
  if [[ $CSS != *'/skwibl-min.css' ]]; then
    cat $CSS >> $CSS_NAME.css
  fi
done

$CLEANCSS -e --s0 -o $CSS_NAME$STAMP-min.css $CSS_NAME.css
gzip -9 $CSS_NAME$STAMP-min.css -c > $CSS_NAME$STAMP-min.css.gz

rm -f $CSS_NAME.css $CSS_NAME$STAMP-min.css
