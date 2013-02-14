#!/bin/bash

. bin/config.sh

function buildWatch {
  echo "building"
  $COFFEE -w -o $JS_OUTPUT_DIR $COFFEE_DIR &
}

## build procedure
function build {
  echo "building"
  $COFFEE -I none -c -o $JS_OUTPUT_DIR $COFFEE_DIR &
}

case "$1" in
  -b|--build)
    build
    exit 0;;
  -w|--buildWatch)
    bin/init.sh
    buildWatch
    exit 0;;
  "?")
    echo "Invalid option $OPTARG. Try $0 -h for help"
    exit 1;;
  *)
    echo "Unknown error while processing options"
    exit 1;;
esac
