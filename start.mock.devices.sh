#!/bin/bash

# launch N mock devices

# launch_delay_seconds is a very important parameter, it sets a delay in seconds between each launched device
# it's sole use is to ensure that each device is mapped to each peer with the same sequence number (device 1 with peer 1, device 2 with peer 2, etc)
# this greatly simplifies debugging
# without the delay, the mapping is (quasi)random as it depends on the arrival time of the peer request messages at the gateway

# eag - 2018-03-16


# arguments
number_of_devices=$1
launch_delay_seconds=$2
start_device_num=$3
gateway_port=$4
gateway_host=$5

# includes
. colors.sh
. verify.class.path.sh

# flags
set -e
set -u

# verify arguments
if [ -z $number_of_devices ]; then red "missing argument 1 : number_of_devices"; exit 1; fi
if [ -z $launch_delay_seconds ]; then orange "missing argument 2 : launch_delay_seconds -> 1"; launch_delay_seconds=1; fi
if [ -z $start_device_num ]; then orange "missing argument 3 : start_device_num -> 1"; start_device_num=1; fi
if [ -z $gateway_port ]; then orange "missing argument 4 : gateway_port -> 3427"; gateway_port=3427; fi
if [ -z $gateway_host ]; then orange "missing argument 5 : gateway_host -> localhost"; gateway_host=localhost; fi
	
echo "number_of_devices : $number_of_devices"
echo "launch_delay_seconds : $launch_delay_seconds"
echo "start_device_num : $start_device_num"
echo "gateway_port : $gateway_port"
echo "gateway_host : $gateway_host"

# constants
end_device_num=$(($start_device_num + $number_of_devices - 1))
echo "end_device_num : $end_device_num"

screenname="gdelt.mock.device.$start_device_num.$end_device_num"
echo "screenname : $screenname"

# verify if screen already exists
if screen -ls | grep "$screenname" ; then 
	red "a screen session with name $screenname already found -> goodbye"
	exit 1
fi 

# launch
screen_exists=0
for i in `seq 1 1 $number_of_devices`; do
	
	device_num=$(($start_device_num + $i -1))
	title="dev#$device_num"
	
	echo -n "launching $title..."
	if [ $screen_exists == 0 ]; then
			# launch new screen session
			screen -d -m -S $screenname -t "$title" bash start.mock.device.sh $device_num $gateway_port $gateway_host
			screen_exists=1
	else
			screen -S $screenname -X screen -t "$title" bash start.mock.device.sh $device_num $gateway_port $gateway_host
	fi
	echo "ok"
	
	
	# wait
	sleep $launch_delay_seconds
	
done

# login
screen -dr $screenname
