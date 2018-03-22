#!/bin/bash

# arguments
sleep_time_minutes=$1
num_rows=$2     # num_rows of random data

# flags
set -e
set -u

# verify arguments
if [ -z $sleep_time_minutes ]; then echo "missing argument 1 : sleep_time_minutes"; exit 1; fi
if [ -z $num_rows ]; then echo "missing argument 2 : num_rows"; exit 1; fi

echo "sleep_time_minutes : $sleep_time_minutes"
echo "num_rows : num_rows"

# constants
sleep_time_seconds=`echo $(($sleep_time_minutes * 60))`
echo "sleep_time_seconds : $sleep_time_seconds"

script=update.py
echo "script : $script"

log=/tmp/$0.log
echo "log : $log"

# files + folders
if [ ! -e $script ]; then echo "$script $script not found"; exit 1; fi
rm -f $log



while [ 1 ]; do

    # update
    echo
    date
    echo "starting update"
    python3 $script $num_rows | tee -a $log


    # sleep
    echo
    echo -n "sleeping $sleep_time_minutes minutes..."
    sleep $sleep_time_seconds
    echo "ok"

done