select
    peer
    ,MAX(dt)
from
    aggregation_event_rrd
GROUP by
    peer
ORDER by
    peer
   ;
   
select MAX(dt) AS last_dt from aggregation_event_rrd
   ;