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


# files + folders

# start

while [ 1 ]; do

    # update
    echo
    echo "--- starting update ---"
    ./update.sh


    # sleep
    echo
    echo -n "sleeping $sleep_time_minutes minutes..."
    sleep $sleep_time_seconds
    echo "ok"

done
