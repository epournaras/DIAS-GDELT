
CREATE VIEW vw_gdelt_map_peer_country AS
WITH w_recent_sample As
(
  SELECT * FROM gdeltv2c ORDER BY seq_id DESC LIMIT 1000
)

SELECT
  peer
  ,actiongeo_countrycode
FROM
  w_recent_sample
GROUP BY
  peer
  ,actiongeo_countrycode
ORDER BY
  peer
  ,actiongeo_countrycode
;