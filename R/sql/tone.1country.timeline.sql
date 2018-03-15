SELECT 
    *
FROM 
    gdelt
WHERE 
    ActionGeo_CountryCode = '<country>' 
ORDER BY
    globaleventid DESC
LIMIT <num.rows>
