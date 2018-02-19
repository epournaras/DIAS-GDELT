SELECT 
    GlobalEventId
    ,sqldate
    ,AvgTone
FROM 
    [gdelt-bq:full.events]
ActionGeo_CountryCode 
WHERE 
    ActionGeo_CountryCode = 'SZ' 
AND
    sqldate BETWEEN 20170209 AND 20180209
ORDER BY
    sqldate DESC
LIMIT 65536 -- pam limit
