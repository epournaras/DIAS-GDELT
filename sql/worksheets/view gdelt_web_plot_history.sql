--TRUNCATE TABLE gdelt_web_plot_history;

VACUUM ANALYZE gdelt_web_plot_history;


SELECT 'gdelt_web_plot' AS src, now(), MIN(dt) AS first_dt, MAX(dt) AS last_dt,MAX(dt) - MIN(dt) AS uptime,  MAX(epoch) as last_epoch,  MAX(epoch) - MIN(epoch) as epoch_range, COUNT(*) AS num_rows FROM gdelt_web_plot

UNION ALL

SELECT 'gdelt_web_plot_history' AS src, now(), MIN(dt) AS first_dt, MAX(dt) AS last_dt,MAX(dt) - MIN(dt) AS uptime, MAX(epoch) as last_epoch,  MAX(epoch) - MIN(epoch) as epoch_range, COUNT(*) AS num_rows FROM gdelt_web_plot_history;

SELECT * FROM gdelt_web_plot_history ORDER BY epoch DESC LIMIT 10;

-- total uptime
--EXPLAIN ANALYZE
SELECT MIN(dt::date) FROM gdelt_web_plot_history;


-- retrieve an aribtrary time window
SELECT 
  *
FROM
  gdelt_web_plot_history
WHERE
  dt::date BETWEEN '2019-01-20 10:00:00' AND '2019-01-20 18:00:00'
  ORDER BY epoch ASC;
ORDER BY epoch DESC LIMIT 100;

-- check indexes on dates
VACUUM ANALYZE gdelt_web_plot_history;

EXPLAIN ANALYZE
SELECT 
  *
FROM
  gdelt_web_plot_history
WHERE
  dt::date BETWEEN '2019-01-20 10:00:00' AND '2019-01-20 18:00:00';