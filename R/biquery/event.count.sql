SELECT 
    sqldate
    ,COUNT(*) AS cnt_events
FROM 
    [gdelt-bq:full.events]
ActionGeo_CountryCode 
WHERE 
    ActionGeo_CountryCode IN ( 'AU', 'BE', 'BU', 'CY', 'EI', 'EN', 'EZ', 'FI', 'FR', 'GM', 'GR', 'HR', 'HU', 'IT', 'LG', 'LH', 'LO', 'LU', 'MT', 'NL', 'PL', 'PO', 'RO', 'SI', 'SP', 'SW', 'SZ', 'UK')
AND
    sqldate BETWEEN 20170209 AND 20180425
GROUP BY
  sqldate
ORDER BY
    sqldate ASC
