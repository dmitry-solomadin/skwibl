#!/bin/bash

. bin/config.sh

## start dynamic server
function startDyn {
  echo "starting dynamic"
  eval "$COFFEE $DYN.iced $COFFEE_OPT"
}

## start socket server
function startSocket {
  echo "starting sockets"
  eval "$COFFEE $SOC.iced $COFFEE_OPT"
}

## run in production procedure
function product {
  echo "production starting"
  eval "NODE_ENV=production $NODE_CMD $DYN.js & NODE_ENV=production  $NODE_CMD $SOC.js"
}

case "$1" in
  -a|--dynamic)
    bin/init.sh
    startDyn
    exit 0;;
  -p|--product)
    bin/init.sh
    product;;
  -s|--socket)
    startSocket
    exit 0;;
  "?")
    echo "Invalid option $OPTARG. Try $0 -h for help"
    exit 1;;
  *)
    echo "Unknown error while processing options"
    exit 1;;
esac
