#!/bin/bash

. bin/config.sh

## check if coffee is installed
if [ ! -e $COFFEE ]; then
  bin/update.sh
fi

## connect procedure
function connect {
  sshpass -p $PASSWORD ssh root@$IP
}

case "$1" in
  -a|--dynamic)
    bin/start.sh -a
    exit 0;;
  -b|--build)
    build
    exit 0;;
  -c|--clean)
    bin/clean.sh
    exit 0;;
  -d|--deploy)
    bin/clean.sh
    bin/init.sh
    build_deploy
    bin/deploy.sh
    bin/clean.sh
    exit 0;;
  -i|--init)
    bin/init.sh
    exit 0;;
  -o|--connect)
    connect;;
  -p|--product)
    bin/start.sh -p;;
  -r|--reset)
    read -p "You are going to reset project files and flush db. Do you want to continue (y/n)?" REPLY
    if [ $REPLY == 'y' ]; then
      bin/clean.sh
      bin/reset.sh
    elif [ $REPLY == 'n' ]; then
      exit 0
    else
      echo 'Reply "y" or "n"'
      eval $0 -r
    fi
    exit 0;;
  -s|--socket)
    bin/start.sh -s
    exit 0;;
  -u|--update)
    bin/update.sh
    exit 0;;
  -w|--dynamicWatch)
    bin/init.sh
    buildWatch
#     startDyn
    exit 0;;
  -h|--help)
    echo -e $USAGE
    exit 0;;
  "?")
    echo "Invalid option $OPTARG. Try $0 -h for help"
    exit 1;;
  *)
    echo "Unknown error while processing options"
    exit 1;;
esac
