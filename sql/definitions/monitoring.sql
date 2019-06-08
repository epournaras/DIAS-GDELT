DROP TABLE monitoring CASCADE;

CREATE TABLE monitoring
(
    -- standard admin fields
	seq_id SERIAL NOT NULL
	,dt TIMESTAMP NOT NULL  DEFAULT NOW()

    -- monitoring fields
    ,last_eval_dt TIMESTAMP NOT NULL
    ,monitor_name TEXT NOT NULL
    ,action TEXT NOT NULL
    ,status TEXT NOT NULL
    ,msg TEXT
    ,df TEXT

);
/
-- partitioning insert function
CREATE OR REPLACE FUNCTION monitoring_insert_trigger() RETURNS TRIGGER AS
$$
DECLARE target_table VARCHAR;

BEGIN
    IF NEW.status LIKE 'ok' THEN
        target_table := 'monitoring_ok';

    ELSIF NEW.status LIKE 'warning' THEN
        target_table := 'monitoring_warning';

    ELSIF NEW.status LIKE 'error' THEN
        target_table := 'monitoring_error';

    ELSE
        target_table := 'monitoring_other';
    END IF;

    EXECUTE format('INSERT INTO %I VALUES( $1.* )', target_table) USING NEW;

RETURN NULL;
END;
$$ LANGUAGE plpgsql;

/

-- insert trigger
CREATE TRIGGER monitoring_trigger BEFORE INSERT ON monitoring FOR EACH ROW EXECUTE PROCEDURE monitoring_insert_trigger();

/

-- create partitions for each type of Status
CREATE TABLE monitoring_ok( CHECK( status LIKE 'ok' ) ) INHERITS (monitoring);
CREATE TABLE monitoring_warning( CHECK( status LIKE 'warning' ) ) INHERITS (monitoring);
CREATE TABLE monitoring_error( CHECK( status LIKE 'error' ) ) INHERITS (monitoring);
CREATE TABLE monitoring_other( CHECK( true ) ) INHERITS (monitoring);

-- indexes for fast sorting on seq_id
 CREATE INDEX CONCURRENTLY monitoring_ok_idx ON monitoring_ok USING BRIN(seq_id);
 CREATE INDEX CONCURRENTLY monitoring_warning_idx ON monitoring_warning USING BRIN(seq_id);
 CREATE INDEX CONCURRENTLY monitoring_error_idx ON monitoring_error USING BRIN(seq_id);
 CREATE INDEX CONCURRENTLY monitoring_other_idx ON monitoring_other USING BRIN(seq_id);

