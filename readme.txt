DIAS-GDELT
edward | 2018-02-19

integrate quasi real-time data from GDELT v2.0, available through Google BigQuery, into DIAS

overall architecture:
- local PostgresSQL database acts as a local cache to minimise Google BigQuery access, since these are subject to data quotas


git clone https://github.com/epournaras/DIAS-GDELT.git

# -----------------------------
# launch sequence (Event Count)
# -----------------------------

# instructions for launching a DIAS/GDELT aggregation network for counting number of events per country 

# 1: persistence daemon
cd DIAS-Logging-System
./start.daemon.sh

# 2: Protopeer Bootstrap server and DIAS Gateway server
cd DIAS-Development
./start.servers.sh

# 3: 30 DIAS Peers, one per country; no need for carrier nodes
cd DIAS-Development
./start.aggregation.peers.sh 30 1 1

# 4. start GDELT subscription
cd /DIAS-GDELT/python/gdeltv2.count
./auto.update.sh

# 4.b optional: listen to GDELT messages
# this displays messages processed by auto.update.sh to screen
cd /DIAS-GDELT/python
python3 zeromq.sub.py

# 5: start GDELT Mock devices (Event Count)
# start 30 mock devices
cd DIAS-GDELT
./start.mock.devices.sh 30

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

