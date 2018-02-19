DIAS-GDELT/python
edward | 2018-02-19

scripts to obtain GDELT data in quasi-realtime from Google Big-Query into a local PostgreSQL database

Python Setup
------------
current interpreter: Python 3.6.3

required packages:
pip3 install google.cloud   # for Google BigQuery
pip install psycopg2        # for PostgreSQL


Google Big-Query Credential Setup
---------------------------------
export GOOGLE_APPLICATION_CREDENTIALS="/Users/edward/Documents/workspace/DIAS-GDELT/python/Quantum Tableau WDC-5dc61916c609.json"

Usages
-----

a) download initial data
python3 download.py fromdate todate

example
python3 download.py 20180216 20180217

format from fromdate and todate : YYYYMMDD
correspond to the field 'sqldate' in the GDELT database

b) update
update data from the last globaleventid in the databsae present
python3 update.py

update data from globaleventid {} to latest
python3 update.py event_lb=21312323





