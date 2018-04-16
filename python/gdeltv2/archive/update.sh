#!/bin/bash

# arguments

# flags
set -e
set -u

# verify arguments

# includes
. colors.sh

# constants
dt=`date +%Y-%m-%d-%H:%M:%S`
echo "dt : $dt"

log=log/$dt.log
echo "log : $log"

downloaddir=downloads
echo "downloaddir : $downloaddir"

parseddir=parsed
echo "parseddir : $parseddir"

downloadstat=download.stat
echo "downloadstat : $downloadstat"

lastupdatefile=lastupdate.txt
echo "lastupdatefile : $lastupdatefile"

lastupdateurl="http://data.gdeltproject.org/gdeltv2/$lastupdatefile"
echo "lastupdateurl : $lastupdateurl"



# files + folders
mkdir -p $parseddir
mkdir -p $downloaddir

rm -f $lastupdatefile
rm -f $downloadstat

# start

# download latest status
#python3 gkg.download.latest.py  | tee -a $log
wget $lastupdateurl
if [ ! -e $lastupdatefile ]; then echo "lastupdatefile $lastupdatefile not found"; exit 1; fi


# determine latest filename
downloadurl=`cat $lastupdatefile | tail -n1 | cut -f3 -d' '`
echo "downloadurl : $downloadurl"

filestem=`basename $downloadurl`
echo "filestem : $filestem"

latestdownload="$downloaddir/$filestem"
echo "latestdownload : $latestdownload"

if [ -e $latestdownload ]; then
    orange "$latestdownload $latestdownload already exists"
    exit 0
else
  wget $downloadurl -O $latestdownload

  # update status file
  echo "dt:$dt" >> $downloadstat
  echo "filestem:$filestem" >> $downloadstat

fi


if [ ! -e $latestdownload ]; then echo "latestdownload $latestdownload not found"; exit 1; fi

# determine name of the downloaded file
decompressed_stem=`echo $filestem | sed 's#.zip##'`
echo "decompressed_stem : $decompressed_stem"

decompressed_file="/tmp/$decompressed_stem"
echo "decompressed_file : $decompressed_file"

# decompress the last update; decompress in tmp folder
# delete decompressed file before, to avoid the prompt
rm -f $decompressed_file
unzip $downloaddir/$filestem -d /tmp

if [ ! -e $decompressed_file ]; then echo "decompressed_file $decompressed_file not found"; exit 1; fi

# parse
outputfile=$parseddir/$decompressed_stem
echo "outputfile : $outputfile"

echo -n "parsing..."
python3 gkg.parse.py $decompressed_file $outputfile > $log 2>&1
echo "ok"

# broadcast over zeromq
if [ ! -e $outputfile ]; then echo "$outputfile $outputfile not found"; exit 1; fi

echo -n "broadcasting over zeromq..."
python3 gkg.publish.py $outputfile  > $log 2>&1
echo "ok"

# persist to database
echo -n "persisting to database zeromq..."
python3 gkg.persist.py $outputfile  > $log 2>&1
echo "ok"

echo "completed"

