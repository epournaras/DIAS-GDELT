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

# writing to PostgreSQL
import psycopg2

# dataframes
import pandas

# epoch
import time

# --------
# platform
# --------
platform = platform.system()
print('platform : ', platform)

# ---------
# arguments
# ---------

# init command line arguments
cmd_line_parser = argparse.ArgumentParser(
	description='read a parsed GDELT data file and persist all records to PostgreSQL')

# add positional arguments
cmd_line_parser.add_argument('input_filename', type=str, help='Name of the input file')

# add optional arguments
cmd_line_parser.add_argument('-d', '--debug', type=bool, help='debugging', default=False)

# parse arguments
cmd_line_args = cmd_line_parser.parse_args()

# ---------
# constants
# ---------
input_filename = cmd_line_args.input_filename

debug = cmd_line_args.debug

dt = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
print('dt : ', dt)

epoch_time = int(time.time())
print('epoch_time : ', epoch_time)

# postgres
pg_sql_insert_template = """INSERT INTO gdeltv2c(dt,epoch,peer,gkgrecordid,sqldate,ActionGeo_CountryCode,EventCount) 
    VALUES(%s,%s,%s,%s,%s,%s,%s)"""

# databse
db_name = 'dias'
db_host = 'localhost'
db_port = '5432'
db_user = 'postgres'
db_pwd = 'postgres'

pg_conn_string = "dbname='" + db_name + "' user='" + db_user + "' host='" + db_host + "' port='" + db_port + "' password='" + db_pwd + "'"

pg_commit_rate = 10000   # commit to db every N rows

# files + folders
assert os.path.isfile(input_filename)

# -------------------
# connect to Postgres
# -------------------
pg_connection = psycopg2.connect(pg_conn_string)
assert pg_connection is not None
print('connected to PostgreSQL')

pg_cursor = pg_connection.cursor()
assert pg_cursor is not None


# read data
row_counter = 0

# keep track of the latest values per country
latest_values = dict()


# iterate on all rows returned
df = pandas.read_csv(input_filename, delimiter='\t')

for index, row in df.iterrows():
	row_counter += 1

	# indivual elements can be accessed by name
	peer = row['peer']
	gkgrecordid = row['gkgrecordid']
	sqldate = row['sqldate']  # this is an integer
	ActionGeo_CountryCode = row['ActionGeo_CountryCode']


	if debug:
		print(row_counter, ':', dt, peer, gkgrecordid, sqldate, ActionGeo_CountryCode, AvgTone)
	else:
		sys.stdout.write('.')
		sys.stdout.flush()

	# update number of events per country
	if ActionGeo_CountryCode not in latest_values:
		latest_values[ActionGeo_CountryCode] = dict()
		latest_values[ActionGeo_CountryCode]['dt'] = dt
		latest_values[ActionGeo_CountryCode]['peer'] = peer
		latest_values[ActionGeo_CountryCode]['gkgrecordid'] = gkgrecordid
		latest_values[ActionGeo_CountryCode]['sqldate'] = sqldate
		latest_values[ActionGeo_CountryCode]['ActionGeo_CountryCode'] = ActionGeo_CountryCode
		latest_values[ActionGeo_CountryCode]['EventCount'] = 1

	else:
		latest_values[ActionGeo_CountryCode]['dt'] = dt
		latest_values[ActionGeo_CountryCode]['gkgrecordid'] = gkgrecordid
		latest_values[ActionGeo_CountryCode]['EventCount'] += 1

# write
for ActionGeo_CountryCode in latest_values:
	try:

		dt = latest_values[ActionGeo_CountryCode]['dt']
		peer = latest_values[ActionGeo_CountryCode]['peer']
		gkgrecordid = latest_values[ActionGeo_CountryCode]['gkgrecordid']
		sqldate = latest_values[ActionGeo_CountryCode]['sqldate']
		EventCount = latest_values[ActionGeo_CountryCode]['EventCount']


		ret = pg_cursor.execute(pg_sql_insert_template,
		                        (dt, epoch_time, peer, gkgrecordid, sqldate, ActionGeo_CountryCode, EventCount,))

		if (row_counter % pg_commit_rate) == 0:
			pg_connection.commit()
			print('committed row ', row_counter)
			print()

	except (Exception, psycopg2.DatabaseError) as error:
		print(error)
		break


# commit data
if row_counter == 0:
    print('no data returned')
else:
    pg_connection.commit()
    print('data committed')

# disconnect from PostgreSQL
pg_cursor.close()
pg_connection.close()

print('disconnected from PostgreSQL')


print('completed')
