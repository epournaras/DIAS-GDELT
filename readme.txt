DIAS-GDELT
edward | 2018-02-19

integrate quasi real-time data from GDELT v2.0, available through Google BigQuery, into DIAS

overall architecture:
- local PostgresSQL database acts as a local cache to minimise Google BigQuery access, since these are subject to data quotas


git clone https://github.com/epournaras/DIAS-GDELT.git

# ---------------
# launch sequence
# ---------------

# instructions for the minimum working 

# screen 1: persistence daemon
cd DIAS-Logging-System
./start.daemon.sh

# screen 2: Protopeer Bootstrap server and DIAS Gateway server
cd DIAS-Development
./start.servers.sh

# screen 3: DIAS Peers, including carrier nodes
cd DIAS-Development
./start.peers.sh 20 1 1 

# screen 4: GDELT BigQuery
# choose one of the following
a) mock (random) data
cd /home/edward/DIAS-GDELT/python/rand
./auto.update.sh 1 100

OR
b) live data
# TODO

# screen 5: Mock devices
# start 10 mock devices, in screen , starting at device number 1
cd DIAS-GDELT
./start.mock.devices.sh 10 1 1

# -------------------------
# installation instructions
# -------------------------

for Ubuntu 16.04 LTS
edward | 2018-03-19

- install Python libs: PostgreSQL, ZeroMQ
sudo apt install python3-pip
pip3 install psycopg2
sudo pip3 install pyzmq

- deploy DIAS
scp -r bin C0:/home/edward/DIAS-Development

- deploy DIAS-GDELT
scp -r bin C0:/home/edward/DIAS-GDELT
scp -r lib C0:/home/edward/DIAS-GDELT
scp -r sql C0:/home/edward/DIAS-GDELT
scp -r python C0:/home/edward/DIAS-GDELT
scp *.sh C0:/home/edward/DIAS-GDELT

- create gdelt tables
in Oracle SQL Developer or psql, run script gdelt_test.sql and/or gdelt.sql, located in DIAS-GDELT/sql/defintions

