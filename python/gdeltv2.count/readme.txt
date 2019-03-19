DIAS-GDELT/python/gdeltv2.count
edward | 2018-04-25

base: DIAS-GDELT/python/gdeltv2

modifications:
1. counts the number of events per country (as opposed to extracting latest AvgTone)

scripts to obtain GDELT Version 2.1. data directly from GDELT

data is updated every 15 minutes

url: for http://data.gdeltproject.org/gdeltv2/lastupdate.txt

use this documentation to understand the fields: GDELT-Global_Knowledge_Graph_Codebook-V2.1.pdf

# requirements
sudo apt-get install unzip
sudo pip3 install html2text
sudo pip install requests

# -----
# start
# -----

1. start GDELT extract utility
    ./auto.update.sh

2. subscribe to news feed
       python3 zeromq.sub.py --p 5556

3. start news processing pipeline
    ./news.worker.sh

# -------
# scripts
# -------

1. gkg.parse.py
    - parse a downloaded GDELT v2.1 file
    - assumes prior decompression of the file

    - usage
        unzip downloads/20180415154500.gkg.csv.zip
        mv 20180415154500.gkg.csv /tmp
        python3 gkg.parse.py /tmp/20180415154500.gkg.csv /tmp/parsed


# -----
# tests
# -----
# listen to news feed
python3 zeromq.sub.py --p 5556

# publish a single news file
python3 gkg.news.publish.py -P True news/20180917084500.gkg.csv

# load a subscription
python3 load.subscription.py subscriptions/test.ini

# load all subscriptions
python3 load.subscriptions.py

# create some test json files
./create.test.json.sh downloads/20180917084500.gkg.csv.zip 100

    # create 20 test files only
    ./create.test.json.sh downloads/20180917084500.gkg.csv.zip 20

    # or manually

    # parse a raw json file, retrieve url and output a new JSON with an additional field 'text'
    cat test/news.json | python3 url.get.text.py -D True

    cat test/news.2.json | python3 url.get.text.py > test/news.retrieved.2.json

# test news.processor
# you will need the text to be retrieved first in the json
cat test/news.retrieved.2.json | python3 news.processor.py -D True
cat test/20180917084500.13.json | python3 news.processor.py -D True

# test news into slack client
cat test/20180917084500.13.json | python3 news.processor.py | python3 slack.client.py