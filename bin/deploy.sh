#!/bin/bash

. bin/config.sh

echo "deploing"

mv $TOOLS_FILE $TOOLS_FILE.save
sed 's/#  / /g' $TOOLS_FILE.save  > $TOOLS_FILE

$COFFEE -I none -c -o $JS_OUTPUT_DIR $COFFEE_DIR

find ./ -name "*.coffee" -o -name "*.iced" -exec $COFFEE -I none -cb {} \;
find $COFFEE_DIR -name "*.js" -delete

rm -f $TOOLS_FILE
mv $TOOLS_FILE.save $TOOLS_FILE

STAMP=`date '+%s'`
bin/minify.sh $STAMP

mv $APPSCRIPT_FILE $APPSCRIPT_FILE.save
sed "s/skwibl\-min\.css/skwibl$STAMP\-min\.css/g" $APPSCRIPT_FILE.save | sed "s/skwibl\.min\.js/skwibl$STAMP\.min\.js/g" > $APPSCRIPT_FILE

echo $STAMP >> assets/deploy_history.txt

sshpass -p $PASSWORD rsync ./pass.rsync -rvuzl ./ root@$IP:/var/www/skwibl/ --exclude '.git' --exclude "*.coffee" --exclude "*.iced" --exclude "client" --exclude "uploads/*" --exclude "assets/js/vendor" --exclude "assets/js/client" --exclude "assets/socket.io" --exclude "assets/css/dev" --exclude $APPSCRIPT_FILE.save

rm -f $APPSCRIPT_FILE
mv $APPSCRIPT_FILE.save $APPSCRIPT_FILE

bin/clean.sh $STAMP
