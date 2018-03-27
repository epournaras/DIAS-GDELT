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

# get URL
import requests

# --------
# platform
# --------
platform = platform.system()
print('platform : ', platform)


# ------
# colors
# ------

# create ANSI escape sequences
class bcolors:
	HEADER = '\033[95m'
	OKBLUE = '\033[94m'
	OKGREEN = '\033[92m'
	WARNING = '\033[93m'
	FAIL = '\033[91m'
	ENDC = '\033[0m'
	BOLD = '\033[1m'
	UNDERLINE = '\033[4m'


# ---------
# arguments
# ---------

# init command line arguments
cmd_line_parser = argparse.ArgumentParser(description='update GDELT data directly from GDELT')

# add positional arguments


# add optional arguments
cmd_line_parser.add_argument('-p','--output_path', type=str, help='name of the output file', default = 'downloads')
cmd_line_parser.add_argument('-d', '--debug', type=bool, help='debugging', default=False)

# parse arguments
cmd_line_args = cmd_line_parser.parse_args()

# ---------
# constants
# ---------
gdelt_update_url = 'http://data.gdeltproject.org/gdeltv2/lastupdate.txt'
print('gdelt_update_url : ', gdelt_update_url)

debug = cmd_line_args.debug
print('debug : ', debug)

output_path = cmd_line_args.output_path
print('output_path : ', output_path)

# -----
# start
# -----

# get information about the last update
gdelt_request = requests.get(gdelt_update_url)
print('status_code:', gdelt_request.status_code)
assert (gdelt_request.status_code == 200)

return_string = str(gdelt_request.content.decode('utf-8'))
print('return_string:', return_string)

gdelt_data_location = str(return_string.split('\n')[0].split(' ')[2])
# gdelt_data_location = str(return_string.split(' ')[3])
print('gdelt_data_location:', gdelt_data_location)


output_filename = os.path.basename(gdelt_data_location)
if output_path is not None:
	output_filename = output_path + '/' + output_filename

print('output_filename:', output_filename)

# download the last update
raw_data_request = requests.get(gdelt_data_location)
print('status_code:', raw_data_request.status_code)
assert (raw_data_request.status_code == 200)

# write to file
with open(output_filename,'wb') as output:
	output.write(gdelt_request.content)


# done
print()
print(bcolors.OKGREEN + '*** completed ***' + bcolors.ENDC)
