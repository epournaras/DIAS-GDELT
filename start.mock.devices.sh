#!/bin/bash

# launch N mock devices

# eag - 2018-08-24


# arguments
deployment=$1		# name of an existing path that contains a conf folder with the required configuration settings, e.g deployments/localhost
number_of_devices=$2
start_device_num=$3

# includes
. colors.sh
. verify.class.path.sh

# flags
set -e
set -u

# verify arguments
if [ -z $deployment ]; then red "missing argument 1 : deployment"; exit 1; fi
if [ -z $number_of_devices ]; then red "missing argument 2 : number_of_devices"; exit 1; fi
if [ -z $start_device_num ]; then orange "missing argument 3 : start_device_num -> 1"; start_device_num=1; fi
	
echo "deployment : $deployment"
echo "number_of_devices : $number_of_devices"
echo "start_device_num : $start_device_num"

# constants
gdelt_config=$deployment/gdelt.conf
echo "gdelt_config : $gdelt_config"

launch_delay_seconds=1
echo "launch_delay_seconds : $launch_delay_seconds"

end_device_num=$(($start_device_num + $number_of_devices - 1))
echo "end_device_num : $end_device_num"

screenname="gdelt.mock.device.$start_device_num.$end_device_num"
echo "screenname : $screenname"

# verify if screen already exists
if screen -ls | grep "$screenname" ; then 
	red "a screen session with name $screenname already found -> goodbye"
	exit 1
fi 


# files + folders
if [ ! -e $deployment ]; then red "deployment $deployment not found"; exit 1; fi
if [ ! -e $gdelt_config ]; then red "gdelt_config $gdelt_config not found"; exit 1; fi


# get gateway settings
# get gateway ip and port
deviceGatewayIP=`cat $gdelt_config | grep deviceGatewayIP | cut -f2 -d '='`
echo "deviceGatewayIP : $deviceGatewayIP"

deviceGatewayPort=`cat $gdelt_config | grep deviceGatewayPort | cut -f2 -d '='`
echo "deviceGatewayPort : $deviceGatewayPort"

if [ -z $deviceGatewayIP ]; then red "could not find deviceGatewayIP in $gdelt_config"; exit 1; fi
if [ -z $deviceGatewayPort ]; then red "could not find deviceGatewayPort in $gdelt_config"; exit 1; fi

# launch
screen_exists=0
for i in `seq 1 1 $number_of_devices`; do
	
	device_num=$(($start_device_num + $i -1))
	title="dev#$device_num"
	
	echo -n "launching $title..."
	if [ $screen_exists == 0 ]; then
			# launch new screen session
			screen -d -m -S $screenname -t "$title" bash start.mock.device.sh $device_num $deviceGatewayPort $deviceGatewayIP
			screen_exists=1
	else
			screen -S $screenname -X screen -t "$title" bash start.mock.device.sh $device_num $deviceGatewayPort $deviceGatewayIP
	fi
	echo "ok"
	
	
	# wait
	sleep $launch_delay_seconds
	
done

# login
screen -dr $screenname
