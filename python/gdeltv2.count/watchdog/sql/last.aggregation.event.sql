SELECT
  globaleventid, sqldate, ActionGeo_CountryCode, AvgTone
  ,DENSE_RANK() OVER (ORDER BY ActionGeo_CountryCode) AS peer

FROM `gdelt-bq.full.events`
WHERE ActionGeo_CountryCode IN
(
  'SZ','AU','BE','BU','HR','CY','EZ','DK','EN','FI','FR',
  'GM','GR','HU','EI','IT','LG','LH','LU','MT','NL','PL',
  'PO','RO','LO','SI','SP','SW','UK'
)
AND
   globaleventid >= {globaleventid_lb}
ORDER BY globaleventid ASC;

