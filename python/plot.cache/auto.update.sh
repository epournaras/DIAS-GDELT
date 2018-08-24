#!/bin/bash

# include
. colors.sh

# arguments
sleep_time_seconds=$1

# flags
set -e
set -u

# verify arguments
if [ -z $sleep_time_seconds ]; then orange "missing argument 1 : sleep_time_seconds -> 1"; sleep_time_seconds=60; fi
echo "sleep_time_seconds : sleep_time_seconds"

# constants
script=cache.py
echo "script : $script"

log=/tmp/$0.log
echo "log : $log"

# files + folders
if [ ! -e $script ]; then echo "script $script not found"; exit 1; fi
rm -f $log


# start
while [ 1 ]; do

    # update
    echo
    date
    echo "starting update"
    python3 $script | tee -a $log


    # sleep
    echo
    echo -n "sleeping $sleep_time_minutes minutes..."
    sleep $sleep_time_seconds
    echo "ok"

done
