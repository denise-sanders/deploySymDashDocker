-- DROP DATABASE IF EXISTS symetric;
CREATE DATABASE symetric
  WITH OWNER = postgres
       ENCODING = 'utf8'
       TABLESPACE = pg_default
       LC_COLLATE = 'English_United States.1252'
       LC_CTYPE = 'English_United States.1252'
       CONNECTION LIMIT = -1;

CREATE TABLE region_cell_rollup_by_test (
    timestamp bigint,
    granularity text,
    source_region text,
    source_cell text,
    destination_region text,
    destination_cell text,
    interface text,
    test_name text,
    metric_key text,
    average float,
    maximum float,
    minimum float,
    points int,
    PRIMARY KEY (timestamp, granularity, source_region, source_cell, destination_region, destination_cell, interface, test_name)
);

CREATE TABLE settings (
    setting_key text,
    setting_value text,
    CONSTRAINT settings_pkey PRIMARY KEY (setting_key)
);

INSERT INTO settings(setting_key, setting_value)
VALUES ('available_resolutions', 'MIN1440|MIN240|MIN60|MIN20|MIN5');


CREATE OR REPLACE FUNCTION dashboard_test_time(ref refcursor, region text, cell text, start bigint, end_ bigint, gran text) RETURNS refcursor AS $$
  BEGIN
    OPEN ref FOR
    SELECT COALESCE(j.timestamp, l.timestamp, lpp.timestamp) as "timestamp",
      jitter_min, jitter_max, jitter_avg, jitter_points,
      latency_min, latency_max, latency_avg, latency_points,
      mbps_sent_percent_min, mbps_sent_percent_max, mbps_sent_percent_avg, mbps_sent_percent_points
    FROM
      (
        SELECT timestamp,  test_name, max(maximum) as jitter_max, min(minimum) as jitter_min, avg(average) as jitter_avg, sum(points) as jitter_points
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'jitter'
              AND granularity = gran
              AND source_region = region
              AND source_cell = cell
              AND timestamp BETWEEN start AND end_
        GROUP BY timestamp, test_name
      ) j
      FULL OUTER JOIN
      (
        SELECT timestamp,  test_name, max(maximum) as latency_max, min(minimum) as latency_min, avg(average) as latency_avg, sum(points) as latency_points
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'latency'
              AND granularity = gran
              AND source_region = region
              AND source_cell = cell
              AND timestamp BETWEEN start AND end_
        GROUP BY timestamp, test_name
      ) l ON j.timestamp = l.timestamp
      FULL OUTER JOIN
      (
        SELECT timestamp,  test_name, max(maximum) as mbps_sent_percent_max, min(minimum) as mbps_sent_percent_min,
          avg(average) as mbps_sent_percent_avg, sum(points) as mbps_sent_percent_points
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'mbps_sent_percent'
              AND granularity = gran
              AND source_region = region
              AND source_cell = cell
              AND timestamp BETWEEN start AND end_
      GROUP BY timestamp, test_name
      ) lpp ON j.timestamp = lpp.timestamp;

    RETURN ref;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION dashboard_cell_time(ref refcursor, region text, start bigint, end_ bigint, gran text) RETURNS refcursor AS $$
  BEGIN
    OPEN ref FOR

    SELECT COALESCE(j.timestamp, l.timestamp, lpp.timestamp) as "timestamp", COALESCE(j.source_cell, l.source_cell, lpp.source_cell) as source_cell,
      latency_max, jitter_max, mbps_sent_percent_max
    FROM
      (
        SELECT timestamp, source_cell, max(maximum) as jitter_max
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'jitter'
              AND granularity = gran
              AND source_region = region
              AND timestamp BETWEEN start  and end_
        GROUP BY timestamp, test_name, source_cell
      ) j
      FULL OUTER JOIN
      (
        SELECT timestamp, source_cell, max(maximum) as latency_max
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'latency'
              AND granularity = gran
              AND source_region = region
              AND timestamp BETWEEN start  and end_
        GROUP BY timestamp, test_name, source_cell
      ) l ON j.timestamp = l.timestamp  and j.source_cell = l.source_cell
      FULL OUTER JOIN
      (
        SELECT timestamp, source_cell,  max(maximum) as mbps_sent_percent_max
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'mbps_sent_percent'
              AND granularity = gran
              AND source_region = region
              AND timestamp BETWEEN start  and end_
      GROUP BY timestamp, test_name, source_cell
      ) lpp ON j.timestamp = lpp.timestamp and j.source_cell = lpp.source_cell;

    RETURN ref;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION dashboard_region_time(ref refcursor, start bigint, end_ bigint, gran text) RETURNS refcursor AS $$
  BEGIN
    OPEN ref FOR

    SELECT COALESCE(j.timestamp, l.timestamp, lpp.timestamp) as "timestamp", COALESCE(j.source_region, l.source_region, lpp.source_region) as source_region,
      latency_max, jitter_max,  mbps_sent_percent_max
    FROM
      (
        SELECT timestamp, source_region, max(maximum) as jitter_max
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'jitter'
              AND granularity = gran
              AND timestamp BETWEEN start  and end_
        GROUP BY timestamp, test_name, source_region
      ) j
      FULL OUTER JOIN
      (
        SELECT timestamp, source_region, max(maximum) as latency_max
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'latency'
              AND granularity = gran
              AND timestamp BETWEEN start  and end_
        GROUP BY timestamp, test_name, source_region
      ) l ON j.timestamp = l.timestamp  and j.source_region = l.source_region
      FULL OUTER JOIN
      (
        SELECT timestamp, source_region,  max(maximum) as mbps_sent_percent_max
        FROM public.region_cell_rollup_by_test
        WHERE test_name = 'mbps_sent_percent'
              AND granularity = gran
              AND timestamp BETWEEN start  and end_
      GROUP BY timestamp, test_name, source_region
      ) lpp ON j.timestamp = lpp.timestamp and j.source_region = lpp.source_Region;

    RETURN ref;
  END;
$$ LANGUAGE plpgsql;

/*  === TESTING ===
    SELECT dashboard_cell_time('test_cur', 'dfw', 1456758900000, 1458058900000, 'MIN5');
    FETCH ALL IN "test_cur";
    SELECT dashboard_region_time('test_cur',  1456758900000, 1458058900000, 'MIN5');
    FETCH ALL IN "test_cur";
    SELECT dashboard_cell_time('test_cur', 'dfw', 'a0002', 1456758900000, 1458058900000, 'MIN5');
    FETCH ALL IN "test_cur";
 */

/* OLD Cassandra parts for use as reference point
CREATE TABLE IF NOT EXISTS symdash.running_data (
    key text,
    value text,
    PRIMARY KEY (key)
) WITH default_time_to_live = 3600; -- 1 hour
CREATE TABLE IF NOT EXISTS symdash.regions (
    name text,
    PRIMARY KEY (name)
) WITH default_time_to_live = 2592000; -- 30 days
CREATE TABLE IF NOT EXISTS symdash.region_cells (
    region text,
    cell text,
    PRIMARY KEY (region, cell)
) WITH default_time_to_live = 2592000; -- 30 days
CREATE TABLE IF NOT EXISTS symdash.metric_keys (
    key text,
    PRIMARY KEY (key)
) WITH default_time_to_live = 86400; -- 1 day
CREATE TABLE IF NOT EXISTS symdash.raw_metric_data (
    timestamp bigint,
    source_region text,
    source_cell text,
    destination_region text,
    destination_cell text,
    interface text,
    test_name text,
    prefix text,
    value float,
    PRIMARY KEY (timestamp, source_region, source_cell, destination_region, destination_cell, interface, test_name)
) WITH default_time_to_live = 2592000; -- 30 days
CREATE TABLE IF NOT EXISTS symdash.region_rollup_by_cell (
    timestamp bigint,
    granularity text,
    region text,
    cell text,
    average float,
    maximum float,
    minimum float,
    points int,
    PRIMARY KEY (timestamp, granularity, region, cell)
) WITH default_time_to_live = 2592000; -- 30 days
*/

