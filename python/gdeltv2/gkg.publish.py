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

# ZeroMQ publish service
import zmq

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
	description='read a parsed GDELT data file and publish the last values per country to ZeroMQ')

# add positional arguments
cmd_line_parser.add_argument('input_filename', type=str, help='Name of the input file')

# add optional arguments
cmd_line_parser.add_argument('-d', '--debug', type=bool, help='debugging', default=False)
cmd_line_parser.add_argument('-p', '--port', type=int, default=5555, help='Zeromq port number')

# parse arguments
cmd_line_args = cmd_line_parser.parse_args()

# ---------
# constants
# ---------
input_filename = cmd_line_args.input_filename

debug = cmd_line_args.debug

dt = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())
print('dt : ', dt)

# files + folders
assert os.path.isfile(input_filename)

# start zeromq publish service
zmq_context = zmq.Context()
print('zmq context created')

zmq_socket = zmq_context.socket(zmq.PUB)
print('zmq socket created')

zmq_socket.bind("tcp://127.0.0.1:" + str(cmd_line_args.port))
time.sleep(1)
print('Connect succeeded')

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
	AvgTone = row['AvgTone']

	if debug:
		print(row_counter, ':', dt, peer, gkgrecordid, sqldate, ActionGeo_CountryCode, AvgTone)
	else:
		sys.stdout.write('.')
		sys.stdout.flush()

	# keep track of last downloaded values
	# this is be necessary for broadcasting the latest value to all the listening devices over ZeroMQ
	latest_values[ActionGeo_CountryCode] = dict()
	latest_values[ActionGeo_CountryCode]['dt'] = dt
	latest_values[ActionGeo_CountryCode]['peer'] = peer
	latest_values[ActionGeo_CountryCode]['gkgrecordid'] = gkgrecordid
	latest_values[ActionGeo_CountryCode]['sqldate'] = sqldate
	latest_values[ActionGeo_CountryCode]['ActionGeo_CountryCode'] = ActionGeo_CountryCode
	latest_values[ActionGeo_CountryCode]['AvgTone'] = AvgTone

print('')

# publish last downloaded values per country to ZeroMQ
print('sending to ZeroMQ')
for country_name, country_value in latest_values.items():
	print('latest values for ' + str(country_name) + ' : ', str(country_value))
	zmq_socket.send_string(str(country_value))
	print('data sent')

# allows peers to process the message, otherwise there is always the risk of shuting down the socket
# before the messages was sent and/or received
print('waiting before closing socket')
time.sleep(5)
print('wait completed')

# close ZeroMQ
zmq_socket.close()
print('disconnected from ZeroMQ')

print('completed')
