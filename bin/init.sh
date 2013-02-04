#!/bin/bash

. bin/config.sh

echo "init project directories"

if [ ! -e $UPLOADS_TMP ]; then
  mkdir -p $UPLOADS_TMP
fi
