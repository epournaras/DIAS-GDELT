-- gdelt_web_plot_7d: table for plotting GDELT data to the website
-- generate by the R script plot.sum.rrd.gdelt.7d.R
-- edward | 2019-06-05

DROP TABLE IF EXISTS gdelt_web_plot_7d;

CREATE TABLE gdelt_web_plot_7d
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
