-- true GDELT values
SELECT * FROM gdeltv2c ORDER BY dt DESC LIMIT 10;

-- check that there is no more than 1 peer value per epoch, else we could be double-counting
SELECT * FROM (
  SELECT epoch, peer, COUNT(*) AS cnt_rows FROM gdeltv2c WHERE epoch is NOT NULL GROUP BY epoch, peer
) a
WHERE
cnt_rows != 1;


SELECT epoch,MAX(dt),SUM(eventcount) AS true_sum_events FROM gdeltv2c WHERE epoch is NOT NULL GROUP BY epoch ORDER BY epoch DESC LIMIT 10;


-- sum of selected states
-- sum of DIAS aggregates
SELECT * FROM aggregation ORDER BY dt DESC LIMIT 10;

-- check that there is no more than 1 peer value per epoch, else we could be double-counting
SELECT * FROM (
  SELECT epoch, peer, COUNT(*) AS cnt_rows FROM aggregation WHERE epoch is NOT NULL GROUP BY epoch, peer
) a
WHERE
cnt_rows != 1;


SELECT
  epoch
  ,MAX(dt)
  ,SUM(state) AS sum_selected_states
  ,SUM(sum) AS sum_dias_aggregates
FROM aggregation WHERE epoch is NOT NULL GROUP BY epoch ORDER BY epoch DESC LIMIT 10;


-- final aggregate query for SASO2019 poster
WITH w_true_aggregates AS
(
  SELECT epoch,MAX(dt) AS dt,SUM(eventcount) AS sum_true_events FROM gdeltv2c WHERE epoch is NOT NULL 
  GROUP BY epoch  

)
,w_peer_aggregates AS 
(
  SELECT
  epoch
  ,MAX(dt)
  ,SUM(state) AS sum_peer_selected_states
  ,AVG(sum) AS avg_peer_dias_aggregates
  ,MAX(sum) - MIN(sum) AS range_peer_dias_aggregates
  FROM aggregation WHERE epoch is NOT NULL 
  GROUP BY epoch

)
SELECT
  t.epoch
  ,t.dt
  ,t.sum_true_events
  ,p.sum_peer_selected_states
  ,p.avg_peer_dias_aggregates
  ,p.range_peer_dias_aggregates
FROM
  w_true_aggregates t
LEFT JOIN
  w_peer_aggregates p
  ON
  p.epoch = t.epoch
;

-- msgs
SELECT * FROM msgs LIMIT 10;
SELECT * FROM eventlog LIMIT 10;
  SELECT * FROM rawlog WHERE error_level != 3 LIMIT 10;
SELECT * FROM aggregation_event LIMIT 10;

