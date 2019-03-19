SELECT * FROM gdeltv2c ORDER BY dt DESC;

SELECT COUNT(*) FROM gdeltv2c;

--TRUNCATE TABLE gdeltv2c;
-- warmup query
WITH w_data AS (SELECT * FROM gdeltv2c WHERE peer = 28 ORDER BY gkgrecordid DESC LIMIT 27) SELECT * FROM w_data ORDER BY gkgrecordid ASC;

-- query for showing the true sum of events
SELECT
  epoch
  ,SUM(eventcount)
FROM  
  gdeltv2c
GROUP BY
  epoch
ORDER BY
  epoch
  ;
  
-- round robin event-based dias aggregates
SELECT * FROM aggregation_event_rrd WHERE network = 0;




