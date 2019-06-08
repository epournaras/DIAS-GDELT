SELECT * FROM gdeltv2 ORDER BY seq_id DESC LIMIT 10;

SELECT 
  extract( hour FROM  dt)
  ,COUNT(*)
  ,AVG(avgtone)
FROM
gdeltv2
GROUP BY
  extract( hour FROM  dt)
  ORDER BY
  extract( hour FROM  dt)
  ;

SELECT 

SELECT
  peer
  ,actiongeo_countrycode
  ,COUNT(*)
FROM
  gdeltv2
GROUP BY 
  peer
  ,actiongeo_countrycode
ORDER BY 
  COUNT(*) DESC
  
  ;
  
-- follow update progress
SELECT
  dt
  ,COUNT(*) as cnt_records
  ,COUNT(DISTINCT peer) as cnt_peers
FROM
  gdeltv2
GROUP BY 
  dt
ORDER BY 
  dt DESC
  ;
