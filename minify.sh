#!/bin/bash

## uglifyjs executable
UGLIFYJS='node_modules/uglify-js/bin/uglifyjs'

## application script name
APP_NAME='./vendor/js/skwibl'

## list of js files
JS_LIST=`cat views/shared/application_scripts.ect | grep -o \"\/.*\.js | tail -n +2 | sed 's/\"\/js\/dev/\.\/vendor\/js\/dev/' | sed 's/\"\/js/\.\/assets\/js/' | sed 's/\"\/socket\.io/\.\/node_modules\/socket\.io\/node_modules\/socket\.io-client\/dist/'`

for SCRIPT in $JS_LIST; do
  cat $SCRIPT >> $APP_NAME.js
done

$UGLIFYJS $APP_NAME.js -c -o $APP_NAME.min.js
gzip -9 $APP_NAME.min.js -c > $APP_NAME.min.js.gz

rm -f $APP_NAME.js $APP_NAME.min.js

cp ./vendor/js/dev/plugins/Jplayer.swf ./vendor/js/Jplayer.swf