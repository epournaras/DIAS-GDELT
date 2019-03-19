-- gdelt_web_plot: table for plotting GDELT data to the website
-- generate by the R script plot.sum.rrd.gdelt.R
-- edward | 2018-09-24

--DROP TABLE IF EXISTS gdelt_web_plot;
CREATE TABLE gdelt_web_plot
(
    -- standard database fields
	seq_id SERIAL NOT NULL
	,dt TIMESTAMP NOT NULL DEFAULT NOW()
    
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
