#!/usr/bin/env python3.4

import argparse
import sys
import zmq

def get_args ():
	parser = argparse.ArgumentParser (description='ZeroMQ Sub')
	parser.add_argument ( '-p', '--port', type=int, default=5555, help='Zeromq port number')
	parser.add_argument ( '-H', '--host', type=str, default='127.0.0.1', help='Zeromq host name')
	args = parser.parse_args ()
	return args
    

def main ():
	args = get_args ()

	context = zmq.Context()

	socket = context.socket(zmq.SUB)

	socket.setsockopt(zmq.SUBSCRIBE, b"")
	socket.setsockopt(zmq.RCVHWM, 100000)

	socket.connect('tcp://' + args.host + ':' + str(args.port))

	while True:
		data = socket.recv_string()
		print(data)

if __name__ == '__main__':
	try:
		main ()
	except KeyboardInterrupt:
		print ('Keyboard interrupt')
		sys.exit(0)
