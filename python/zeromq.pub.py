#!/usr/bin/env python3.4

import argparse
import sys
import zmq

def get_args ():
    parser = argparse.ArgumentParser (description='ZeroMQ Pub')
    parser.add_argument ( '-p', '--port', type=int, default=5555, help='Zeromq port number')
    args = parser.parse_args ()
    return args
    

def main ():
    args = get_args ()

    print('port : ', args.port)

    context = zmq.Context()
    print( 'zmq context created' )

    socket = context.socket(zmq.PUB)
    print('zmq socket created')

    socket.bind("tcp://127.0.0.1:" + str(args.port))
    print('Connected')

    print('listening to stdin:')

    # read from stdin
    for raw_line in sys.stdin:
        line = raw_line.strip()
        socket.send_string(line)
        print('-> ---', line, '---')

if __name__ == '__main__':
    try:
        main ()
    except KeyboardInterrupt:
        print ('Keyboard interrupt')
        sys.exit(0)
