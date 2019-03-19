DIAS-GDELT
edward | 2019-03-19


# ------------
# introduction
# ------------

Have you ever wondered how many news event are produced every day in Europe? 

To demonstrate the real-world applicability and feasibility to perform real-time distributed data analytics, we connected DIAS into GDELT to measure the number of news events in Europe, updated every 15 minutes. Such news events are a good indicator of the overall activity level of the continent. Indeed, if more news items are being produced, then it is likely that more physical events are taking place. And vice-versa.

The following application connects DIAS into GDELT. GDELT is the largest publicly available collection of near real-time news feed in the World, connecting to hundreds of newsfeeds and delivering updates every 15-minutes. 

This DIAS application covers the 28 countries in Europe. Each country is represented by a DIAS node, so there are 28 DIAS nodes in the network that are cooperating to provide analytics about th

# ------------
# installation
# ------------

0. System Requirements
	- OSX or Ubuntu >= 14
	- 1Gb Ram

1. setup the DIAS Logging System, that can be found at https://github.com/epournaras/DIAS-Logging-System.git

2. install DIAS, that can be found at https://github.com/epournaras/DIAS-Development.git

	- be sure to use branch pilot.2017.f 

3. install DIAS-GDELT, that can be found here: https://github.com/epournaras/DIAS-GDELT

# ------
# launch
# ------

1. Launch the DIAS-Logging-System, by launching the persistence daemon (that listens for messages to be logged and writes them to the database).
cd DIAS-Logging-System
./start.daemon.sh deployments/gdelt

2. Launch Protopeer Bootstrap server and DIAS Gateway server
cd DIAS-Development
./start.servers.sh deployments/gdelt

3. Launch 28 DIAS Peers, one per country; no need for carrier nodes
cd DIAS-Development
./start.aggregation.peers.sh deployments/gdelt 28 1 1

4. Start GDELT subscription
cd DIAS-GDELT/python/gdeltv2.count
./auto.update.sh

5. start 28 GDELT Mock devices
cd DIAS-GDELT
 ./start.mock.devices.sh deployments/gdelt 28