#!/bin/bash

. bin/config.sh

echo "resetting"

rm -rf $MODULES_DIR
rm -rf $UPLOADS
rm -f $JS_OUTPUT_DIR/*.*

eval $FLUSH_REDIS_CMD

bin/update.sh

if [ `uname -s` == 'Linux' ]; then
  sudo nginx -s stop
  mkdir -p /etc/haproxy
  sudo update-rc.d haproxy remove
  sudo cp -f $EXTERNAL/nginx.conf /etc/nginx/
  sudo cp -f $EXTERNAL/haproxy.cfg /etc/haproxy/
  sudo cp -f $EXTERNAL/haproxy /etc/init.d/
  sudo update-rc.d haproxy defaults
  sudo nginx
  sudo service haproxy restart
fi
