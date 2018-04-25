#!/bin/bash

# launch a mock peer, that will connect with the dias.bootstrap.gateway

# usages:
# ./start.gateway.sh {peer.id}

# eag - 2017-10-11


# arguments
device_id=$1
gateway_port=$2
gateway_host=$3


# includes
. colors.sh
. verify.class.path.sh

# flags
set -e
set -u

# verify arguments
if [ -z $device_id ]; then red "missing argument 1 : device_id"; exit 1; fi
if [ -z $gateway_port ]; then orange "missing argument 2 : gateway_port -> 3427"; gateway_port=3427; fi
if [ -z $gateway_host ]; then orange "missing argument 3 : gateway_host -> localhost"; gateway_host=localhost; fi
	
	
echo "device_id : $device_id"
echo "gateway_port : $gateway_port"
echo "gateway_host : $gateway_host"

# classpath
classpath_src="$eclipse_build_path:../gson/$eclipse_build_path:../jeromq/$eclipse_build_path:../DIAS-GUI/integration-gui/msgs/$eclipse_build_path:lib/*"
#classpath_src="$eclipse_build_path:../gson/$eclipse_build_path:../jeromq3-x/$eclipse_build_path:../DIAS-GUI/integration-gui/msgs/$eclipse_build_path:lib/*"
echo "classpath_src : $classpath_src"

classpath_lib="$eclipse_build_path:lib/postgresql-42.1.4.jar:lib/gson.jar:lib/jeromq.jar:lib/msgs.jar:lib/*"
#classpath_lib="$eclipse_build_path:lib/postgresql-42.1.4.jar:lib/gson.jar:lib/jeromq3.jar:lib/msgs.jar:lib/*"
echo "classpath_lib : $classpath_lib"

# test different flavors of the Mock Device
#mock_device_type="diasgdelt.MockGdeltDevice"
mock_device_type="diasgdelt.MockGdeltDeviceEventCount"		 
echo "mock_device_type : $mock_device_type"

# constants
logdir=mock/devices
echo logdir : $logdir
 
logfile=$logdir/$device_id.log
echo "logfile : $logfile"

epoch_seconds=`date +%s`
echo "epoch_seconds : $epoch_seconds"


# verify java class path
# verify java class path
verify_class_path "$classpath_src"
echo "class_path_verified : $class_path_verified"

if [ $class_path_verified == 1 ]; then
	classpath=$classpath_src
	echo "using source classpath"
	
else
	echo "trying alternative -> verifying lib classpath"
	verify_class_path "$classpath_lib"
	echo "class_path_verified : $class_path_verified"


	if [ $class_path_verified == 1 ]; then
		classpath=$classpath_lib
		echo "using lib classpath"
	else
		red "no classpath available (either source or lib)"
		exit 1
	fi
fi

echo
echo "classpath : $classpath"
echo

# files + folders
mkdir -p $logdir
rm -f $logfile


# start
java -cp "$classpath" $mock_device_type $device_id $gateway_port $gateway_host | tee -a $logfile
