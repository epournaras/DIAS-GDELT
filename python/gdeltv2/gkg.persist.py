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

# postgres
pg_sql_insert_template = """INSERT INTO gdeltv2(dt,peer,gkgrecordid,sqldate,ActionGeo_CountryCode,AvgTone) 
    VALUES(%s,%s,%s,%s,%s,%s)"""

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

# iterate on all rows returned
df = pandas.read_csv(input_filename, delimiter='\t')

for index, row in df.iterrows():
	row_counter += 1

	# indivual elements can be accessed by name
	peer = row['peer']
	gkgrecordid = row['gkgrecordid']
	sqldate = row['sqldate']  # this is an integer
	ActionGeo_CountryCode = row['ActionGeo_CountryCode']
	AvgTone = row['AvgTone']

	if debug:
		print(row_counter, ':', dt, peer, gkgrecordid, sqldate, ActionGeo_CountryCode, AvgTone)
	else:
		sys.stdout.write('.')
		sys.stdout.flush()

	# write
	try:
		ret = pg_cursor.execute(pg_sql_insert_template,
		                        (dt, peer, gkgrecordid, sqldate, ActionGeo_CountryCode, AvgTone,))

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
