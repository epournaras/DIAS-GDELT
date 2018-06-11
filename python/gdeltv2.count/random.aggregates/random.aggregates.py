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

# random data generation
import random

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
	description='generate and persist random DIAS aggregates into the database')

# add positional arguments

# add optional arguments
cmd_line_parser.add_argument('--num_countries', type=int, help='random data generation', default=28)
cmd_line_parser.add_argument('--every_n_minutes', type=int, help='random data generation', default=15)
cmd_line_parser.add_argument('--noise', type=int, help='random data generation', default=10)
cmd_line_parser.add_argument('-d', '--debug', type=bool, help='debugging', default=False)

# parse arguments
cmd_line_args = cmd_line_parser.parse_args()

# ---------
# constants
# ---------
debug = cmd_line_args.debug
print('debug:',debug)

num_countries = cmd_line_args.num_countries
print('num_countries:',num_countries)

every_n_minutes = cmd_line_args.every_n_minutes
print('every_n_minutes:',every_n_minutes)

max_events = 200
print('max_events:',max_events)

noise = cmd_line_args.noise
print('noise:',noise)

# postgres
sql_insert_template = """INSERT INTO aggregation(dt,peer,network,epoch,active,state,avg,sum,max,min,count) 
    VALUES(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"""


# database connection settings
db_name = 'dias'
db_host = 'localhost'
db_port = '5432'
db_user = 'postgres'
db_pwd = 'postgres'

pg_conn_string = "dbname='" + db_name + "' user='" + db_user + "' host='" + db_host + "' port='" + db_port + "' password='" + db_pwd + "'"

pg_commit_rate = num_countries   # commit to db every N rows

# files + folders


# -------------------
# connect to Postgres
# -------------------
pg_connection = psycopg2.connect(pg_conn_string)
assert pg_connection is not None
print('connected to PostgreSQL')

pg_cursor = pg_connection.cursor()
assert pg_cursor is not None

# generate initial data
generate_new_data = True

# read data
epoch_counter = 0

true_aggregates = dict()
peer_info = dict()      # peer_info[peer_id] = dict()


while True:

	epoch_counter += 1

	dt = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())

	# generate new data every every_n_minutes
	if generate_new_data:

		print('')
		print('--')
		print(dt,)
		print('generating new data')

		true_avg = 0
		true_sum = 0
		true_max = -1
		true_min = max_events + 1
		true_count = num_countries

		# generate a random number of events per country
		for peer_id in range(1, num_countries + 1):

			# create new dictionnary for peer
			if peer_id not in peer_info:
				peer_info[peer_id] = dict()

			this_peer_sum = random.randint(1,max_events)
			peer_info[peer_id]['state'] = this_peer_sum

			# update totals
			true_sum += this_peer_sum

			if this_peer_sum > true_max:
				true_max = this_peer_sum

			if this_peer_sum < true_min:
				true_min = this_peer_sum

		# simulate aggregated values infered by each peer
		true_avg = float(true_sum) / float(true_count)

		# save true aggregates
		true_aggregates['avg'] = true_avg
		true_aggregates['sum'] = true_sum
		true_aggregates['max'] = true_max
		true_aggregates['min'] = true_min
		true_aggregates['count'] = true_count

		print('true aggregates:',true_aggregates)

		generate_new_data = False

	# generate some noise
	assert len(true_aggregates) > 0

	for peer_id in range(1, num_countries + 1):
		peer_info[peer_id]['avg'] = true_aggregates['avg'] + random.randint(-noise, noise)
		peer_info[peer_id]['sum'] = true_aggregates['sum'] + random.randint(-noise, noise)
		peer_info[peer_id]['max'] = true_aggregates['max'] + random.randint(-noise, noise)
		peer_info[peer_id]['min'] = true_aggregates['min'] + random.randint(-noise, noise)
		peer_info[peer_id]['count'] = true_aggregates['count'] + random.randint(-noise, noise)


		if debug:
			print('new data for peer', peer_id,':',peer_info[peer_id])



	# write data
	for country_num in range(1,num_countries + 1):

		# set fields
		peer_id = country_num   # each country is associated with a single peer
		network = 0             # default DIAS network
		epoch = epoch_counter
		active = True           # GDELT peers never leave

		assert peer_id in peer_info
		state = peer_info[peer_id]['state']
		avg = peer_info[peer_id]['avg']
		sum = peer_info[peer_id]['sum']
		max = peer_info[peer_id]['max']
		min = peer_info[peer_id]['min']
		count = peer_info[peer_id]['count']


		# write data for this peer
		ret = pg_cursor.execute(sql_insert_template,
			                        (dt,str(peer_id),str(network),str(epoch),str(active),str(state),str(avg),str(sum),str(max),str(min),str(count),))

	# save data for all peers
	pg_connection.commit()

	# generate new data on next epoch ?
	if ((epoch_counter / 60) % every_n_minutes) == 0:
		generate_new_data = True

	# sleep
	time.sleep(1)

	if not debug:
		sys.stdout.write('.')
		sys.stdout.flush()


# disconnect from PostgreSQL
pg_cursor.close()
pg_connection.close()

print('disconnected from PostgreSQL')


print('completed')
