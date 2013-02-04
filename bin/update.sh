#!/bin/bash

. bin/config.sh

echo "updating"

npm install -d
npm update
bin/patch.sh
