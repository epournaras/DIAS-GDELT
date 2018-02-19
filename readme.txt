DIAS-GDELT
edward | 2018-02-19

integrate quasi real-time data from GDELT v2.0, available through Google BigQuery, into DIAS

overall architecture:
- local PostgresSQL database acts as a local cache to minimise Google BigQuery access, since these are subject to data quotas


git clone https://github.com/epournaras/DIAS-GDELT.git
