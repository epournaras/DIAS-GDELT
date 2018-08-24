
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

# --------
# platform
# --------
platform = platform.system()
print('platform : ', platform)

# ---------
# arguments
# ---------

# init command line arguments
cmd_line_parser = argparse.ArgumentParser(description='update GDELT data from Google BigQuery')

# add positional arguments
#cmd_line_parser.add_argument('globaleventid_lb', type=str, help='download events starting at this event id')

# add optional arguments
cmd_line_parser.add_argument('-n', '--num_rows', type=int, help='number of rows to cache', default=50000)
cmd_line_parser.add_argument('-D', '--debug', type=bool, help='debugging', default=False)

# parse arguments
cmd_line_args = cmd_line_parser.parse_args()

num_rows = cmd_line_args.num_rows

# ---------
# constants
# ---------


sql_template_filename = 'read.latest.sql'

gdelt_bq_projectname = 'quantum-tableau-wdc'

# debuging
debug = cmd_line_args.debug


# Google BigQuery timeout, in seconds
timeout = 30

current_time_str = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
print('current_time_str : ',current_time_str)


# constants
pg_sql_insert_template = """INSERT INTO aggregation_plot(seq_id,dt,peer,network,epoch,active,state,avg,sum,max,min,count) VALUES ( %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s )"""

# PostgreSQL constants
db_name = 'dias'
db_host = 'localhost'
db_port = '5432'
db_user = 'postgres'
db_pwd = 'postgres'

pg_conn_string = "dbname='" + db_name + "' user='" + db_user + "' host='" + db_host + "' port='" + db_port + "' password='" + db_pwd + "'"

# files + folders
assert os.path.isfile(sql_template_filename)

# connect to Postgres
pg_connection = psycopg2.connect(pg_conn_string)
assert pg_connection is not None
print('connected to PostgreSQL')


# -----------
# start a txn
# -----------


# ----------------
# delete all data
# ----------------

pg_cursor_delete = pg_connection.cursor()
assert pg_cursor_delete is not None

pg_cursor_delete.execute('DELETE FROM aggregation_plot')
print('data deleted')

# ----------------
# read latest data
# ----------------

# read SQL template for getting data from Google
sql_template = open(sql_template_filename, 'r').read()
#print('sql_template : ' + sql_template)

# replace parameter tokens
query = sql_template.replace('<num.rows>', str(num_rows))
print('query : ' + query)

pg_cursor_read = pg_connection.cursor()
assert pg_cursor_read is not None

pg_cursor_read.execute(query)


# --------------
# write to cache
# --------------


pg_cursor_write = pg_connection.cursor()
assert pg_cursor_write is not None


# iterate on all rows returned
row_counter = 0
while True:

	record = pg_cursor_read.fetchone()    # alternatively use fetchall()

	# detect EOF
	if record is None:
		break

	# check 12 fields read
	assert len(record) == 12

	row_counter += 1

	if (row_counter % 1000) == 0:
		sys.stdout.write('.')
		sys.stdout.flush()


	# replace None with NULL
	records_write = list()
	for i in range(0, 12):
		if record[i] is not None:
			records_write.append(str(record[i]))
		else:
			records_write.append('-1.0')


	if debug:
		for i in range(0,12):
			print( i,':',str(record[i]),' -> ', records_write[i])

	# write
	ret = pg_cursor_write.execute(pg_sql_insert_template, (str(records_write[0]),str(records_write[1]),str(records_write[2]),str(records_write[3]),str(records_write[4]),
	                                                       str(records_write[5]),str(records_write[6]),str(records_write[7]),str(records_write[8]),str(records_write[9]),
	                                                       str(records_write[10]),str(records_write[11]),)
	                              )


print()
print('done')
# commit data

pg_connection.commit()
print('data committed')


# disconnect from PostgreSQL
pg_cursor_delete.close()
pg_cursor_read.close()
pg_cursor_write.close()
pg_connection.close()

print('disconnected from PostgreSQL')
