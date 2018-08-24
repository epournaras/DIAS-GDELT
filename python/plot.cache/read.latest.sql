SELECT
    seq_id
    ,dt
    ,network
    ,peer
    ,epoch
    ,active
    ,state
    ,avg
    ,sum
    ,max
    ,min
    ,count
FROM
    aggregation
WHERE
    network = 0
ORDER BY
    seq_id DESC
LIMIT <num.rows>