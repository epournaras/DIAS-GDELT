
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

# ZeroMQ publish service
import zmq



# --------
# platform
# --------
platform = platform.system()
print('platform : ', platform)

# ---------
# arguments
# ---------

# init command line arguments
cmd_line_parser = argparse.ArgumentParser(description='update GDELT data directly from GDELT')

# add positional arguments
#cmd_line_parser.add_argument('globaleventid_lb', type=str, help='download events starting at this event id')

# add optional arguments
cmd_line_parser.add_argument('-e', '--globaleventid_lb', type=int, help='download events starting at this event id', default=-1)
cmd_line_parser.add_argument('-d', '--debug', type=bool, help='debugging', default=False)

cmd_line_parser.add_argument ('-p', '--port', type=int, default=5555, help='Zeromq port number')
cmd_line_parser.add_argument('-q', '--queuesize', type=int, default=10, help='Zeromq send HWM')

# parse arguments
cmd_line_args = cmd_line_parser.parse_args()

# ---------
# constants
# ---------
globaleventid_lb = cmd_line_args.globaleventid_lb

gdelt_update_url = 'http://data.gdeltproject.org/gdeltv2/lastupdate.txt'
print('gdelt_update_url : ',gdelt_update_url)


# debuging
debug = cmd_line_args.debug


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

pg_commit_rate = 10000   # commit to db every N rows

# files + folders
assert os.path.isfile(sql_template_filename)

# connect to Postgres
pg_connection = psycopg2.connect(pg_conn_string)
assert pg_connection is not None
print('connected to PostgreSQL')

pg_cursor = pg_connection.cursor()
assert pg_cursor is not None

# optional: if user has not specified the first globaleventid to download, then automatically determine
# it by reading from the database
# conn.cursor will return a cursor object, you can use this cursor to perform queries
if globaleventid_lb == -1:
    print('retrieving last globaleventid from database')
    get_last_globaleventid_cursor = pg_connection.cursor()

    get_last_globaleventid_cursor.execute('SELECT MAX(globaleventid) AS max_globaleventid FROM gdelt')

    # retrieve the records from the database
    records = get_last_globaleventid_cursor.fetchone()

    #print(records)
    # get value; only a single value in the recordset
    last_event_db = int(records[0])
    print('last_event_db : ' + str(last_event_db))

    globaleventid_lb = last_event_db + 1


assert globaleventid_lb >= 1
print('globaleventid_lb : ' + str(globaleventid_lb))


# start zeromq publish service
zmq_context = zmq.Context()
print( 'zmq context created' )

zmq_socket = zmq_context.socket(zmq.PUB)
print('zmq socket created')

zmq_socket.bind("tcp://127.0.0.1:" + str(cmd_line_args.port))
time.sleep(1)
print('Connect succeeded')


# TODO: get information about the last update
# gdelt_update_url

# TODO: get the last update

# TODO: convert to list of dicts()

row_counter = 0

# keep track of the latest values per country
latest_values = dict()

# iterate on all rows returned
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

    # keep track of last downloaded values
    # this is be necessary for broadcasting the latest value to all the listening devices over ZeroMQ
    latest_values[ActionGeo_CountryCode] = dict()
    latest_values[ActionGeo_CountryCode]['dt'] = dt
    latest_values[ActionGeo_CountryCode]['peer'] = peer
    latest_values[ActionGeo_CountryCode]['globaleventid'] = globaleventid
    latest_values[ActionGeo_CountryCode]['sqldate'] = sqldate
    latest_values[ActionGeo_CountryCode]['ActionGeo_CountryCode'] = ActionGeo_CountryCode
    latest_values[ActionGeo_CountryCode]['AvgTone'] = AvgTone


print('')
if execute_gbq:
    print('query_job.state : ' + query_job.state)
print('rows returned : ' + str(row_counter))


# commit data
if row_counter == 0:
    print('no data returned')
else:
    pg_connection.commit()
    print('data committed')


    # publish last downloaded values per country to ZeroMQ
    print('sending to ZeroMQ')
    for country_name,country_value in latest_values.items():
        print('latest values for ' + str(country_name) + ' : ', str(country_value))
        zmq_socket.send_string(str(country_value))
        print('data sent')

    # allows peers to process the message, otherwise there is always the risk of shuting down the socket
    # before the messages was sent and/or received
    print('waiting')
    time.sleep(5)
    print('wait completed')

# disconnect from PostgreSQL
pg_cursor.close()
pg_connection.close()

print('disconnected from PostgreSQL')

# close ZeroMQ
zmq_socket.close()
print('disconnected from ZeroMQ')