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
cmd_line_parser = argparse.ArgumentParser(description='Parse a GDELT gkg file')

# add positional arguments
cmd_line_parser.add_argument('filename', type=str, help='file to parse')
cmd_line_parser.add_argument('output', type=str, help='output filename')

# add optional arguments
cmd_line_parser.add_argument('-d', '--debug', type=bool, help='debugging', default=False)
cmd_line_parser.add_argument('-r', '--stop_on_Nth_row', type=int, help='debugging', default=1e6)

# parse arguments
cmd_line_args = cmd_line_parser.parse_args()

# ---------
# constants
# ---------

filename = cmd_line_args.filename
print('filename : ', filename)

output_filename = cmd_line_args.output
print('output_filename : ', output_filename)

debug = cmd_line_args.debug
print('debug : ', debug)

stop_on_Nth_row = cmd_line_args.stop_on_Nth_row
print('stop_on_Nth_row:', stop_on_Nth_row)

countries = dict()
countries['AU'] = 1
countries['BE'] = 2
countries['BU'] = 3
countries['CY'] = 4
countries['EI'] = 5
countries['EN'] = 6
countries['EZ'] = 7
countries['FI'] = 8
countries['FR'] = 9
countries['GM'] = 10
countries['GR'] = 11
countries['HR'] = 12
countries['HU'] = 13
countries['IT'] = 14
countries['LG'] = 15
countries['LH'] = 16
countries['LO'] = 17
countries['LU'] = 18
countries['MT'] = 19
countries['NL'] = 20
countries['PL'] = 21
countries['PO'] = 22
countries['RO'] = 23
countries['SI'] = 24
countries['SP'] = 25
countries['SW'] = 26
countries['SZ'] = 27
countries['UK'] = 28

# filter by georaphic specificity
# 1=COUNTRY
# 2=USSTATE (match was to a US state)
# 3=USCITY (match was to a US city or landmark)
# 4=WORLDCITY (match was to a city or landmark outside the US)
# 5=WORLDSTATE (match was to an Administrative Division 1 outside the US – roughly equivalent to a US state).

locationTypeList = list()
locationTypeList.append(1)
locationTypeList.append(2)
locationTypeList.append(3)
locationTypeList.append(4)
locationTypeList.append(5)

num_countries = len(countries)
print('num_countries:', num_countries)

# -----
# start
# -----

# prepare output
file_output = open(output_filename, 'w')
file_output.write('dt\tpeer\tgkgrecordid\tsqldate\tActionGeo_CountryCode\tAvgTone\n')

# parse
row_counter = 0
parse_warnings = 0
relevant_counter = 0
missing_geo_data = 0

with open(filename) as f:
	try:
		for line in f:

			row_counter += 1

			print()
			print('--- row ', row_counter, '---')
			print(line)

			fields = line.split('\t')
			print('#fields:', len(fields))

			if len(fields) != 27:
				print(bcolors.WARNING + 'incorrect number of fields found on row ' + str(row_counter) + ' : ' + str(len(fields)) + bcolors.ENDC)
				parse_warnings += 1
			else:

				# 0. timestamp
				dt = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime())

				# 1. GKGRECORDID:
				# the GKG system uses a date-oriented serial number.
				# full date+time of the 15 minute update batch that this record was created in
				# followed by a dash, followed by sequential numbering for all GKG records created as part of that update batch
				gkgrecordid = fields[0]
				print('gkgrecordid:', gkgrecordid)

				# 2. sqldate; extract the YYYYMMDD from GKGRECORDID
				sqldate = gkgrecordid[0:8]
				print('sqldate:', sqldate)

				# optional
				# src
				event_src = fields[3]
				print('event_src:', event_src)

				event_url = fields[4]
				print('event_url:', event_url)

				# 3. AvgTone: extract field V1.5TONE (see the documentation GDELT-Global_Knowledge_Graph_Codebook-V2.1.pdf)
				tones = fields[15].split(',')

				print('tones vector:', tones)
				assert (len(tones) == 7)

				# AvgTone:  This is the average “tone” of the document as a whole.
				# it's the first value from the tone vector
				AvgTone = tones[0]
				print('AvgTone:', AvgTone)

				# 4. extract ActionGeo_CountryCode
				geodata_fields = fields[10]
				print('geodata_fields:', geodata_fields)

				geodata = geodata_fields.split('#')
				print('geodata:', geodata)

				if len(geodata) < 2:
					print(bcolors.WARNING + 'unable to parse the geo data' + bcolors.ENDC)
					parse_warnings += 1
					missing_geo_data += 1

				else:

					LocationType = int(geodata[0])
					print('LocationType:', LocationType)

					# we only want LocationType 1 (COUNTRY)
					if LocationType in locationTypeList:
						print('LocationType passes filter')

						ActionGeo_CountryCode = geodata[2]
						print('ActionGeo_CountryCode:', ActionGeo_CountryCode)

						# 5. extract peer id from country code
						peer = None
						if ActionGeo_CountryCode in countries:
							print('CountryCode passes filter')

							peer = countries[ActionGeo_CountryCode]
							print('peer:', peer)

							print(bcolors.OKBLUE + '*** relevant ***' + bcolors.ENDC)
							relevant_counter += 1

							file_output.write(str(dt) + '\t'
							                  + str(peer) + '\t'
							                  + str(gkgrecordid) + '\t'
							                  + str(sqldate) + '\t'
							                  + str(ActionGeo_CountryCode) + '\t'
							                  + str(AvgTone) + '\n')

							file_output.flush()

							print('data written')
				# if geodata[2] == 'UK':
				#	print('debug exit')
				#	exit(1)

			# end of line
			if row_counter >= stop_on_Nth_row:
				print('stopping on row ', row_counter)
				break

	except UnicodeDecodeError:
		print(bcolors.WARNING + 'UnicodeDecodeError after row ' + str(row_counter) + bcolors.ENDC)
		parse_warnings += 1

	#except:
	#	print(bcolors.WARNING + 'unhandled exception after row ' + str(row_counter) + bcolors.ENDC)
	#	parse_warnings += 1

# done

file_output.close()

print()
print(bcolors.OKGREEN + '*** completed ***' + bcolors.ENDC)

print('row_counter:', row_counter)
print('parse_warnings:', parse_warnings)
print('missing_geo_data:', missing_geo_data)
print('relevant_counter:', relevant_counter)
