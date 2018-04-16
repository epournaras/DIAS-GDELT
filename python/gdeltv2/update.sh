#!/bin/bash

# arguments

# flags
set -e
set -u

# verify arguments

# includes
. colors.sh

# platform
platform=`echo $OSTYPE | tr -d '\r'`
echo "platform : $platform"

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

update_url_template="http://data.gdeltproject.org/gdeltv2/{YYYY}{MM}{DD}{HH24}{MI}00.gkg.csv.zip"
echo "update_url_template : $update_url_template"

# debugging
zeromq=1
echo "zeromq : $zeromq"

parse=1
echo "parse : $parse"

persist=1
echo "persist : $persist"

MI_override=-1		# set to -1 to disable
echo "MI_override : $MI_override"

# get current year, month, day, etc
# gdelt time is GMT, 2 hours prior to current time
# e.g 2018-04-15 11:24:05
if [ "$platform" == "linux-gnu" ]; then
	gdelt_download_time=`date --date="2 hours ago" "+%Y-%m-%d %H:%M:%S"`
else
	gdelt_download_time=`date -v-120M "+%Y-%m-%d %H:%M:%S"`
fi


echo "gdelt_download_time : $gdelt_download_time"

YYYY=`echo $gdelt_download_time | cut -f1 -d' ' | cut -f1 -d'-'`
echo "YYYY : $YYYY"

MM=`echo $gdelt_download_time | cut -f1 -d' ' | cut -f2 -d'-'`
echo "MM : $MM"

DD=`echo $gdelt_download_time | cut -f1 -d' ' | cut -f3 -d'-'`
echo "DD : $DD"

HH24=`echo $gdelt_download_time | cut -f2 -d' ' | cut -f1 -d':'`
echo "HH24 : $HH24"

MI=`echo $gdelt_download_time | cut -f2 -d' ' | cut -f2 -d':'`
echo "MI : $MI"

if [[ $MI_override != -1 ]]; then
	MI=$MI_override
	orange "MI override -> $MI"
fi

# determine if it is time to retrieve the update
# gdelt updates every 15 minutes
if [[ $MI == 00 ]] || [[ $MI == 15 ]] || [[ $MI == 30 ]] || [[ $MI == 45 ]]; then
	echo "time for update!"
else
	echo "nothing to do"
	exit 0
fi



# files + folders
mkdir -p $parseddir
mkdir -p $downloaddir

rm -f $downloadstat

# start



# determine name of file to download
downloadurl=`echo $update_url_template | sed s#{YYYY}#$YYYY# | sed s#{MM}#$MM# | sed s#{DD}#$DD# | sed s#{HH24}#$HH24# | sed s#{MI}#$MI#`
echo "downloadurl : $downloadurl"

filestem=`basename $downloadurl`
echo "filestem : $filestem"

latestdownload="$downloaddir/$filestem"
echo "latestdownload : $latestdownload"

if [ -e $latestdownload ]; then
    orange "$latestdownload $latestdownload already exists"
    exit 0
fi

# check if download already exists
# wget -q --spider returns 0 if URL exists, else some other number (e.g 8)
set +e

download_available=-1

# try for a total of 48 * 5 seconds = 4 minutes
# if after that lapse, the file is still not available, cancel
for i in `seq 1 1 48`; do
	wget -q --spider $downloadurl
	download_available=$?

	if [ $download_available == 0 ]; then
		break
	else
		dt=`date +%Y-%m-%d-%H:%M:%S`
		orange "attempt $i : $dt: $downloadurl not yet available"
		sleep 5
	fi
done
set -e

if [ $download_available == 0 ]; then
	green "download available"
else
	orange "$latestdownload $latestdownload not avaialble"
	exit 0
fi




# proceed with download
echo "downloading $downloadurl"
wget $downloadurl -O $latestdownload

# update status file
echo "dt:$dt" >> $downloadstat
echo "filestem:$filestem" >> $downloadstat




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
if [ $parse == 1 ]; then
    outputfile=$parseddir/$decompressed_stem
    echo "outputfile : $outputfile"

    echo -n "parsing..."
    python3 gkg.parse.py $decompressed_file $outputfile > $log 2>&1
    echo "ok"

    # broadcast over zeromq
    if [ ! -e $outputfile ]; then echo "$outputfile $outputfile not found"; exit 1; fi

    if [ $zeromq == 1 ]; then
        echo -n "broadcasting over ZeroMQ..."
        python3 gkg.publish.py $outputfile  > $log 2>&1
        echo "ok"
    else
        orange "skipping ZeroMQ broadcast"

    fi

    # persist to database
    if [ $persist == 1 ]; then
        echo -n "persisting to database..."
        python3 gkg.persist.py $outputfile  > $log 2>&1
        echo "ok"
    else
        orange "skipping persist"
    fi
fi
green "--- update successull ---"

