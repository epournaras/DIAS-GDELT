DELETE FROM gdelt WHERE globaleventid = 734194048;

SELECT      * FROM      gdelt WHERE      ActionGeo_CountryCode = 'SZ'  ORDER BY     globaleventid DESC LIMIT 5000;

--DELETE FROM gdelt WHERE seq_id = 36057;

735456487

SELECT
	COUNT(*)
FROM 
gdelt
WHERE
globaleventid >= (735456487+1)