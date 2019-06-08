SELECT COUNT(*), MIN(dt), MAX(dt), (((MAX(epoch) - MIN(epoch))) / (60 * 60) )  AS hours FROM gdelt_web_plot;;

SELECT COUNT(*), MIN(dt), MAX(dt), (((MAX(epoch) - MIN(epoch))) / (60 * 60) )  AS hours FROM gdeltv2c;;

SELECT * FROM gdelt_web_plot ORDER BY epoch DESC;

sql <- 'SELECT epoch,SUM(eventcount) AS true_sum_events FROM gdeltv2c WHERE epoch is NOT NULL GROUP BY epoch ORDER BY epoch'