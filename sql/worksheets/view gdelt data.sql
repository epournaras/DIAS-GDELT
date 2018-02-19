SELECT * FROM gdelt;

SELECT COUNT(*) FROM gdelt;

SELECT 
    actiongeo_countrycode
    ,MIN(avgtone)
    ,MAX(avgtone)
    ,AVG(avgtone)
    ,COUNT(*) 
FROM 
    gdelt
GROUP BY
    actiongeo_countrycode
ORDER BY
    actiongeo_countrycode
;
    