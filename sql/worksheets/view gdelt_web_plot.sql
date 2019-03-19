SELECT COUNT(*), MIN(dt), MAX(dt), (((MAX(epoch) - MIN(epoch))) / (60 * 60) )  AS hours FROM gdelt_web_plot;;

SELECT * FROM gdelt_web_plot ORDER BY epoch DESC;