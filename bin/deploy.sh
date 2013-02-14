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
bin/minify.sh
read -p "Press any key to continue"
sshpass -p $PASSWORD rsync ./pass.rsync -rvuzl ./ root@$IP:/var/www/skwibl/ --exclude '.git' --exclude "*.coffee" --exclude "*.iced" --exclude "client" --exclude "uploads/*" --exclude "assets/js/vendor" --exclude "assets/js/client" --exclude "assets/socket.io" --exclude "assets/css/dev"
