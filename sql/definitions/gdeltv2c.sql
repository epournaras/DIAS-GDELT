-- gdelt: table for holding GDELT v2 data
-- contains the necessary and sufficient fields for operating DIAS using GDELT dat
-- GDELT data is located here : http://data.gdeltproject.org/gdeltv2/20180327161500.gkg.csv.zip
-- edward | 2018-03-27

--DROP TABLE IF EXISTS gdeltv2c;
CREATE TABLE gdeltv2c
(
    -- standard database fields
	seq_id SERIAL NOT NULL
	,dt TIMESTAMP NOT NULL
    
    -- DIAS fields
    -- DIAS fields directly into the database, for 1:1 mapping with the peers
    -- this saves a required mapping that would have to be done at a later stage
    ,epoch BIGINT 
    ,peer INTEGER NOT NULL
    
    -- GDELT v2 fields
    ,gkgrecordid TEXT NOT NULL                   -- the GKG system uses a date-oriented serial number.
    ,sqldate INTEGER NOT NULL                   -- Date the event took place in YYYYMMDD format; careful! it's an integer!!
	,ActionGeo_CountryCode TEXT NOT NULL        -- Location of Event.  This is the 2-character FIPS10-4 country code for the location
	,EventCount INT NOT NULL                     -- This is the number of events for the country that occurred in the past 15 minutees
);

-- fast lookup indexes
CREATE INDEX CONCURRENTLY gdeltv2c_seq_idx ON gdeltv2c USING BRIN(seq_id);
CREATE INDEX CONCURRENTLY gdeltv2c_epoch_idx ON gdeltv2c USING BRIN(epoch);

CREATE INDEX CONCURRENTLY gdeltv2c_date_idx ON gdeltv2c USING BTREE (cast(dt as date));

CREATE INDEX CONCURRENTLY gdeltv2c_sqldate_idx ON gdeltv2c USING BTREE (sqldate);
CREATE INDEX CONCURRENTLY gdeltv2c_country_idx ON gdeltv2c USING BTREE (ActionGeo_CountryCode);