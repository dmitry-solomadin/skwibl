#!/bin/bash

. bin/config.sh

echo "patching"

cp -Rf $PATCHES_DIR/* $MODULES_DIR
