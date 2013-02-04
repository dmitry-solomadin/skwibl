#!/bin/bash

. bin/config.sh

echo "deploing"

mv $TOOLS_FILE $TOOLS_FILE.save
sed 's/#  / /g' $TOOLS_FILE.save  > $TOOLS_FILE
$COFFEE -I none -c -o $JS_OUTPUT_DIR $COFFEE_DIR
find ./ -name "*.coffee" -o -name "*.iced" -exec $COFFEE -I none -cb {} \;
find ./assets/coffee -name "*.js" -delete
rm -f $TOOLS_FILE
mv $TOOLS_FILE.save $TOOLS_FILE
./minify.sh
sshpass -p $PASSWORD rsync ./pass.rsync -rvuzl ./ root@$IP:/var/www/skwibl/ --exclude '.git' --exclude "*.coffee" --exclude "*.iced" --exclude "assets" --exclude "uploads/*" --exclude "assets/js/vendor" --exclude "assets/js/client" --exclude "assets/socket.io" --exclude "assets/css/dev"
