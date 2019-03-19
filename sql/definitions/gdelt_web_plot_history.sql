-- gdelt_web_plot_history: table for plotting GDELT data to the website
-- table is automatically update on each update to gdelt_web_plot, using a trigger
-- contains indexes on the following fields for fast hitorical lookup
-- 1. seq_id BRIN
-- 2. dt
-- 3. epoch BRIN

-- edward | 2019-01-20
TRUNCATE TABLE gdelt_web_plot_history;
DROP TABLE IF EXISTS gdelt_web_plot_history;

CREATE TABLE gdelt_web_plot_history
(
  
  -- exact same fields as gdelt_web_plot, except DEFAULT values are removed
	seq_id BIGINT NOT NULL
	,dt TIMESTAMP NOT NULL
    
    -- DIAS fields
    ,epoch BIGINT NOT NULL
    
    -- summary aggregation fields
    ,true_sum_gdelt_events FLOAT 
    ,sum_selected_states FLOAT 
    ,dias_sum_selected_states FLOAT 
    
    -- each peer's aggregation appears as a separate column
    ,peer1 FLOAT
    ,peer2 FLOAT
    ,peer3 FLOAT
    ,peer4 FLOAT
    ,peer5 FLOAT
    ,peer6 FLOAT
    ,peer7 FLOAT
    ,peer8 FLOAT
    ,peer9 FLOAT
    ,peer10 FLOAT
    
    ,peer11 FLOAT
    ,peer12 FLOAT
    ,peer13 FLOAT
    ,peer14 FLOAT
    ,peer15 FLOAT
    ,peer16 FLOAT
    ,peer17 FLOAT
    ,peer18 FLOAT
    ,peer19 FLOAT
    ,peer20 FLOAT
        
    ,peer21 FLOAT
    ,peer22 FLOAT
    ,peer23 FLOAT
    ,peer24 FLOAT
    ,peer25 FLOAT
    ,peer26 FLOAT
    ,peer27 FLOAT
    ,peer28 FLOAT
);

-- update trigger
-- table is automatically update on each update to gdelt_web_plot, using a trigger
-- round-robin update function + trigger
-- on each update of aggregation, update aggregation_plot and delete old rows
CREATE OR REPLACE FUNCTION gdelt_web_plot_history_update() RETURNS TRIGGER AS 
$$ 

DECLARE last_epoch BIGINT; 
BEGIN  

    -- to avoid duplicates, only inser new observations into the history table
    SELECT MAX(epoch) 
    INTO last_epoch
    FROM
      gdelt_web_plot_history
    ;
    
    IF last_epoch IS NULL OR ( NEW.epoch > last_epoch ) THEN 
      INSERT INTO gdelt_web_plot_history VALUES (NEW.*);
    END IF; 
    
RETURN NULL; 
END;  
$$ LANGUAGE plpgsql;

/ 
DROP TRIGGER IF EXISTS gdelt_web_plot_history_trigger ON gdelt_web_plot;

/
-- insert trigger; calls the round-robin update function before updating aggregation
-- note that the ideally we should have AFTER INSERT, but it does not work
CREATE TRIGGER gdelt_web_plot_history_trigger AFTER INSERT ON gdelt_web_plot FOR EACH ROW EXECUTE PROCEDURE gdelt_web_plot_history_update();

/

-- indexes
-- contains indexes on the following fields for fast hitorical lookup
-- 1. seq_id BRIN
-- 2. dt
-- 3. epoch BRIN
CREATE INDEX CONCURRENTLY gdelt_web_plot_history_seq_idx ON gdelt_web_plot_history USING BRIN(seq_id);	
CREATE INDEX CONCURRENTLY gdelt_web_plot_history_epoch_idx ON gdelt_web_plot_history USING BRIN(epoch);	
--DROP INDEX gdelt_web_plot_history_date_idx;
CREATE INDEX CONCURRENTLY gdelt_web_plot_history_date_idx ON gdelt_web_plot_history USING BTREE (cast(dt as date));
