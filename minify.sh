#!/bin/bash

## uglifyjs executable
UGLIFYJS='node_modules/uglify-js/bin/uglifyjs'

## cleancss executable
CLEANCSS='node_modules/clean-css/bin/cleancss'

## application script name
JS_NAME='./vendor/js/skwibl'

## application style name
CSS_NAME='./vendor/css/skwibl'

## list of js files
JS_LIST=`cat views/shared/application_scripts.ect | grep -o '\/js.*\.js' | tail -n +2 | sed 's/\/js\/dev/\.\/vendor\/js\/dev/' | sed 's/\/js/\.\/assets\/js/' | sed 's/\/socket\.io/\.\/node_modules\/socket\.io\/node_modules\/socket\.io-client\/dist/'`

## list of css files
CSS_LIST=`cat views/shared/application_scripts.ect | grep -o '\/css.*\.css' | sed 's/^/\.\/vendor/'`

for SCRIPT in $JS_LIST; do
  cat $SCRIPT >> $JS_NAME.js
done

$UGLIFYJS $JS_NAME.js -c -o $JS_NAME.min.js
gzip -9 $JS_NAME.min.js -c > $JS_NAME.min.js.gz

rm -f $JS_NAME.js $JS_NAME.min.js

cp ./vendor/js/dev/plugins/Jplayer.swf ./vendor/js/Jplayer.swf

for CSS in $CSS_LIST; do
  cat $CSS >> $CSS_NAME.css
done

$CLEANCSS -e --s0 -o $CSS_NAME-min.css $CSS_NAME.css
gzip -9 $CSS_NAME-min.css -c > $CSS_NAME-min.css.gz

rm -f $CSS_NAME.css $CSS_NAME-min.css
