-- gdelt: table for holding GDELT data
-- contains the necessary and sufficient fields for operating DIAS using GDELT dat
-- GDELT data is located here : https://bigquery.cloud.google.com/table/gdelt-bq:full.events?pli=1
-- edward | 2018-02-19

DROP TABLE IF EXISTS gdelt;
CREATE TABLE gdelt
(
    -- standard database fields
	seq_id SERIAL NOT NULL
	,dt TIMESTAMP NOT NULL
    
    -- DIAS fields
    -- DIAS fields directly into the database, for 1:1 mapping with the peers
    -- this saves a required mapping that would have to be done at a later stage
    ,epoch BIGINT 
    ,peer INTEGER NOT NULL
    
    -- GDELT fields
    ,globaleventid INTEGER NOT NULL             -- Unique ID for each event
    ,sqldate INTEGER NOT NULL                   -- Date the event took place in YYYYMMDD format; careful! it's an integer!!
	,ActionGeo_CountryCode TEXT NOT NULL        -- Location of Event.  This is the 2-character FIPS10-4 country code for the location
	,AvgTone FLOAT NOT NULL                     -- This is the average tone of all documents containing one or more mentions of this event.  The score ranges from -100 (extremely negative) to +100 (extremely positive).  Common values range between -10 and +10, with 0 indicating neutral.  
);

-- fast lookup indexes
CREATE INDEX CONCURRENTLY gdelt_seq_idx ON gdelt USING BRIN(seq_id);
CREATE INDEX CONCURRENTLY gdelt_epoch_idx ON gdelt USING BRIN(epoch);
CREATE INDEX CONCURRENTLY gdelt_globaleventid_idx ON gdelt USING BRIN(globaleventid);       -- fast lookup of the last globaleventid downloaded

CREATE INDEX CONCURRENTLY gdelt_date_idx ON gdelt USING BTREE (cast(dt as date));

CREATE INDEX CONCURRENTLY gdelt_sqldate_idx ON gdelt USING BTREE (sqldate);
CREATE INDEX CONCURRENTLY gdelt_country_idx ON gdelt USING BTREE (ActionGeo_CountryCode);