#!/bin/bash

# create.test.json.sh
# create single news items files, with retrieved text
# each news item is stored as a JSON file in the folder 'test'
# this allows for testing the individual news items

# edward | 2018-09-17

# example
#./create.test.json.sh downloads/20180917084500.gkg.csv.zip 20

# includes
. colors.sh

# arguments
input_file=$1
number_items=$2

# flags
set -e
set -u

# verify arguments
if [ -z $input_file ]; then red "missing argument 1: input_file"; exit 1; fi
if [ -z $number_items ]; then red "missing argument 2: number_items"; exit 1; fi

# platform
platform=`echo $OSTYPE | tr -d '\r'`
echo "platform : $platform"

# constants
dt=`date +%Y-%m-%d-%H:%M:%S`
echo "dt : $dt"

testdir=test
echo "testdir : $testdir"

parseddir=parsed
echo "parseddir : $parseddir"

log=log/$0.log
echo "log : $log"


# files + folders
if [ ! -e $input_file ]; then red "input_file $input_file not found"; exit 1; fi

mkdir -p log
mkdir -p $testdir
mkdir -p $parseddir

# -----
# start
# -----
filestem=`basename $input_file`
echo "filestem : $filestem"

gdelt_file_id=`echo $filestem | cut -f1 -d '.'`
echo "gdelt_file_id : $gdelt_file_id"

# determine name of the downloaded file
decompressed_stem=`echo $filestem | sed 's#.zip##'`
echo "decompressed_stem : $decompressed_stem"

decompressed_file="/tmp/$decompressed_stem"
echo "decompressed_file : $decompressed_file"

# decompress the last update; decompress in tmp folder
# delete decompressed file before, to avoid the prompt
rm -f $decompressed_file
unzip $input_file -d /tmp

if [ ! -e $decompressed_file ]; then echo "decompressed_file $decompressed_file not found"; exit 1; fi


# parse file
echo
parsedoutputfile=$parseddir/$decompressed_stem
echo -n "parsing file -> $parsedoutputfile..."
python3 gkg.news.parse.py $decompressed_file $parsedoutputfile > $log 2>&1
echo "ok"


# get urls
json=/tmp/$gdelt_file_id.json

echo -n "retrieving URLs -> $json..."
python3 gkg.news.json.py $parsedoutputfile | \
head -n$number_items | \
python3 url.get.text.py > $json
echo "ok"


# create test files, one file per row
count=0
while read -r line
do
    #echo "$line"

    count=`echo $(($count + 1))`

    out=$testdir/"$gdelt_file_id"."$count".json

    # write to file
    echo -n "$count: $out..."
    echo "$line" > $out
    echo "ok"


done < "$json"



# done
echo "$0: completed"

exit 0