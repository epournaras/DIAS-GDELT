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