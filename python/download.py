
# -------
# imports
# -------

import os
import time
import sys

# platform: windows, linux
import platform

# command line largs
import argparse

# Google BigQuery
from google.cloud import bigquery


# writing to PostgreSQL
import psycopg2



# --------
# platform
# --------
platform = platform.system()
print('platform : ', platform)

# ---------
# arguments
# ---------

# init command line arguments
cmd_line_parser = argparse.ArgumentParser(description='download GDELT data from Google BigQuery')

# add positional arguments
cmd_line_parser.add_argument('date_lb', type=str, help='download start date, the value of the field sqldate; format YYYYMMDD')
cmd_line_parser.add_argument('date_ub', type=str, help='download end date, the value of the field sqldate; format YYYYMMDD')

# add optional arguments
cmd_line_parser.add_argument('-d', '--debug', type=bool, help='debugging', default=False)

# parse arguments
cmd_line_args = cmd_line_parser.parse_args()

print('date_lb : ' + cmd_line_args.date_lb)
print('date_ub : ' + cmd_line_args.date_ub)

# ---------
# constants
# ---------
debug = cmd_line_args.debug

sql_template_filename = 'sql/download.template.sql'

gdelt_bq_projectname = 'quantum-tableau-wdc'

# Google BigQuery timeout, in seconds
timeout = 30

current_time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
print('current_time_str : ',current_time_str)


# constants
pg_sql_insert_template = """INSERT INTO gdelt(dt,peer,globaleventid,sqldate,ActionGeo_CountryCode,AvgTone) 
    VALUES(%s,%s,%s,%s,%s,%s)"""

# PostgreSQL constants
db_name = 'dias'
db_host = 'localhost'
db_port = '5432'
db_user = 'postgres'
db_pwd = 'postgres'

pg_conn_string = "dbname='" + db_name + "' user='" + db_user + "' host='" + db_host + "' port='" + db_port + "' password='" + db_pwd + "'"

pg_commit_rate = 1000   # commit to db every N rows

# files + folders
assert os.path.isfile(sql_template_filename)

# connect to Postgres
pg_connection = psycopg2.connect(pg_conn_string)
assert pg_connection is not None
print('connected to PostgreSQL')

pg_cursor = pg_connection.cursor()
assert pg_cursor is not None



# read SQL template for getting data from Google
sql_template = open(sql_template_filename, 'r').read()
#print('sql_template : ' + sql_template)

# replace parameter tokens
query = sql_template.replace('{date_lb}', cmd_line_args.date_lb).replace('{date_ub}', cmd_line_args.date_ub)
print('query : ' + query)


# connect to Google BigQuery
client = bigquery.Client(project=gdelt_bq_projectname)
print('connected to BigQuery')
# execute the query
query_job = client.query(query)
print('query_job.state : ' + query_job.state)

rows = query_job.result()  # Waits for query to finish

row_counter = 0
for row in rows:

    row_counter += 1

    # indivual elements can be accessed by name
    dt = current_time_str
    peer = row['peer']
    globaleventid = row['globaleventid']
    sqldate = row['sqldate']  # this is an integer
    ActionGeo_CountryCode = row['ActionGeo_CountryCode']
    AvgTone = row['AvgTone']

    if debug:
        print(row_counter,':',dt,peer,globaleventid,sqldate,ActionGeo_CountryCode,AvgTone)
    else:
        sys.stdout.write('.')
        sys.stdout.flush()


    # write
    try:
        ret = pg_cursor.execute(pg_sql_insert_template, (dt, peer, globaleventid, sqldate, ActionGeo_CountryCode, AvgTone,))

        if (row_counter % pg_commit_rate) == 0:
            pg_connection.commit()
            print('committed row ', row_counter)
            print()

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        break


print('query_job.state : ' + query_job.state)

# disconnect from PostgreSQL
pg_connection.commit()
pg_cursor.close()
pg_connection.close()

print('disconnected from PostgreSQL')