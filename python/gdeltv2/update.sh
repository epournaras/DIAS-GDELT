#!/bin/bash

# arguments

# flags
set -e
set -u

# verify arguments

# constants
log=log/update.log
echo "log : $log"

downloaddir=downloads
echo "downloaddir : $downloaddir"

parseddir=parsed
echo "parseddir : $parseddir"

dt=`date +%Y-%m-%d-%H:%M:%S`
echo "dt : $dt"

# files + folders
mkdir -p $parseddir
mkdir -p $downloaddir

# start

# download
latestfile=$downloaddir/$dt.txt
if [ -e $latestfile ]; then echo "latestfile $latestfile already exists"; exit 1; fi
python3 gkg.download.latest.py  >> $log

# TODO: determine latest filename
latestfile=...

# TODO: decompress the last update

# parse
if [ ! -e $latestfile ]; then echo "latestfile $latestfile not found"; exit 1; fi
outputfile=$parseddir/$dt.txt
python3 gkg.parse.py $latestfile $outputfile >> $log

# broadcast over zeromq
if [ ! -e $outputfile ]; then echo "$outputfile $outputfile not found"; exit 1; fi
python3 gkg.publish.py $outputfile -p 5555 >> $log

