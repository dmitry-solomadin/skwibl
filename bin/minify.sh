#!/bin/bash

. bin/config.sh

## list of js files
JS_LIST=`cat views/shared/application_scripts.ect | grep -o '\/js.*\.js' | sed 's/\/js/\.\/assets\/js/' | sed 's/\.\/assets\/js\/dev/\.\/vendor\/js\/dev/'`

## list of css files
CSS_LIST=`cat views/shared/application_scripts.ect | grep -o '\/css.*\.css' | sed 's/^/\.\/vendor/'`

cat $SOCKETIO >> $JS_NAME.js
for SCRIPT in $JS_LIST; do
  if [[ $SCRIPT != *'/skwibl.min.js' ]]; then
    cat $SCRIPT >> $JS_NAME.js
  fi
done

$UGLIFYJS $JS_NAME.js -c -o $JS_NAME.min.js
gzip -9 $JS_NAME.min.js -c > $JS_NAME.min.js.gz

rm -f $JS_NAME.js $JS_NAME.min.js

cp ./vendor/js/dev/Jplayer.swf ./vendor/js/Jplayer.swf

for CSS in $CSS_LIST; do
  if [[ $CSS != *'/skwibl-min.css' ]]; then
    cat $CSS >> $CSS_NAME.css
  fi
done

$CLEANCSS -e --s0 -o $CSS_NAME-min.css $CSS_NAME.css
gzip -9 $CSS_NAME-min.css -c > $CSS_NAME-min.css.gz

rm -f $CSS_NAME.css $CSS_NAME-min.css
