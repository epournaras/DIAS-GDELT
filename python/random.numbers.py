#!/usr/bin/env python3.4

import random
import argparse
import sys
import time

def get_args ():
	parser = argparse.ArgumentParser (description='Random numbers')
	parser.add_argument ( '-s', '--sleep_time', type=int, default=1, help='Sleep time in seconds')
	args = parser.parse_args ()
	return args
    

def main ():
	args = get_args ()

	while True:
		print(random.randint(-10,10))
		sys.stdout.flush()

		time.sleep(args.sleep_time)   # delays for 5 seconds

if __name__ == '__main__':
    try:
        main ()
    except KeyboardInterrupt:
        print ('Keyboard interrupt')
        sys.exit(0)
