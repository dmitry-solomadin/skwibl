#!/bin/bash

. bin/config.sh

sshpass -p $PASSWORD ssh root@$IP
