SELECT * FROM vw_global_status;

SELECT 
  date_trunc('day', dt)
  ,monitor_name
  ,status
  ,count(*)
  ,max(dt) AS last_dt
FROM
  monitoring
GROUP BY
  date_trunc('day', dt)
  ,monitor_name
  ,status
ORDER BY 
  date_trunc('day', dt) DESC
  ,monitor_name
  ,status
;

-- prep work for vw_global_status
-- expose status as a single row only with status that contains:
-- 1. stale monitor
-- 2. errors
WITH w_get_last AS (
  SELECT
    monitor_name
    ,MAX(seq_id) AS last_seq_id
  FROM
    monitoring
  WHERE
    monitor_name IN ('DIAS GDELT Download', 'DIAS Aggregation Event Rrd')
  GROUP BY 
    monitor_name
  ORDER BY
    monitor_name
)
,w_join AS (
  SELECT
    m.*
    ,now() - m.dt AS monitor_elapsed_time
  FROM
    monitoring m
  INNER JOIN
    w_get_last l
    ON
    m.seq_id = l.last_seq_id
  ORDER BY
    m.monitor_name
)
,w_flags AS
(
  SELECT 
    CASE WHEN monitor_name = 'DIAS Aggregation Event Rrd' AND status = 'ok' AND monitor_elapsed_time < interval '1' hour THEN 1 ELSE 0 END AS flg_dias
    ,CASE WHEN monitor_name = 'DIAS GDELT Download' AND status = 'ok' AND monitor_elapsed_time < interval '1' hour THEN 1 ELSE 0 END AS flg_download
    ,j.*
  FROM
    w_join j
)
SELECT
  CASE WHEN (SUM(flg_dias) + SUM(flg_download)) = 2 THEN 1 ELSE 0 END AS status
  ,MAX(monitor_elapsed_time) AS max_monitor_elapsed_time
  ,SUM(flg_dias) AS flg_dias
   ,SUM(flg_download) AS flg_download
  
FROM
  w_flags
;
  



SELECT * FROM monitoring ORDER BY seq_id DESC LIMIT 2000;

-- view errors
-- use partitions
SELECT * FROM monitoring_error ORDER BY seq_id DESC;

SELECT * FROM monitoring_warning ORDER BY seq_id DESC;