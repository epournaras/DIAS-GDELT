#!/bin/bash

# include
. colors.sh

# arguments
sleep_time_minutes=$1

# flags
set -e
set -u

# verify arguments
if [ -z $sleep_time_minutes ]; then orange "missing argument 1 : sleep_time_minutes -> 1"; sleep_time_minutes=1; fi
echo "sleep_time_minutes : $sleep_time_minutes"

# constants
sleep_time_seconds=`echo $(($sleep_time_minutes * 60))`
echo "sleep_time_seconds : $sleep_time_seconds"

script=update.py
echo "script : $script"

log=/tmp/$0.log
echo "log : $log"

google_big_query_key="/Users/edward/Documents/workspace/DIAS-GDELT/python/Quantum Tableau WDC-5dc61916c609.json"
echo "google_big_query_key : $google_big_query_key"

# files + folders
if [ ! -e $google_big_query_key ]; then echo "google_big_query_key $google_big_query_key not found"; exit 1; fi
rm -f $log


# start
export GOOGLE_APPLICATION_CREDENTIALS="$google_big_query_key"

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
