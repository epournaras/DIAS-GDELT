SELECT * FROM gdelt_test ORDER BY seq_id DESC;

SELECT COUNT(*) FROM gdelt;

-- last event in the db
SELECT MAX(globaleventid) FROM gdelt;

SELECT 
    actiongeo_countrycode
    ,MIN(avgtone)
    ,MAX(avgtone)
    ,AVG(avgtone)
    ,MAX(dt) AS max_dt
    ,MAX(sqldate) AS max_sqldate
    ,MAX(globaleventid) AS max_globaleventid
    ,MAX(peer) AS peer
    ,COUNT(*) 
FROM 
    gdelt
GROUP BY
    actiongeo_countrycode
ORDER BY
    actiongeo_countrycode
;

-- latest values per country
WITH w_latest_values AS
(
    SELECT
        actiongeo_countrycode
        ,MAX(globaleventid) AS last_globaleventid
    FROM
        gdelt
    GROUP BY 
        actiongeo_countrycode
    ORDER BY 
        actiongeo_countrycode
)   
SELECT
    gdelt_data.*
FROM
    w_latest_values latest_values
INNER JOIN
    gdelt gdelt_data
    ON 
    gdelt_data.actiongeo_countrycode = latest_values.actiongeo_countrycode
    AND
    gdelt_data.globaleventid = latest_values.last_globaleventid
ORDER BY
    gdelt_data.actiongeo_countrycode
;

