\set ECHO queries
--\set SINGLESTEP

DROP SCHEMA IF EXISTS partitioning_demo CASCADE;
CREATE SCHEMA partitioning_demo;

SET search_path TO partitioning_demo;

CREATE TABLE log_entries (
    inserted timestamptz default now(),
    value text
)
PARTITION BY RANGE (inserted);

DO LANGUAGE plpgsql $dynsql$
DECLARE
    boundaries tstzrange := (null, '2000-01-01T00:00:00+00');
    partition_interval interval := '3 months';
    partition_name_format text := '"log_entries_y"yyyy"q"q';
    sql_create_partition text := 'CREATE TABLE %I (LIKE %I INCLUDING ALL)';
    sql_attach_partition text := 'ALTER TABLE %I ATTACH PARTITION %I FOR VALUES FROM (%s) TO (%s)';
    table_name text := 'log_entries';
    partition_name text;
BEGIN

    partition_name := table_name||'_ancient';
    WHILE upper(boundaries) < now() + 2 * partition_interval
    LOOP
        EXECUTE format(sql_create_partition, partition_name, table_name);
        EXECUTE format(sql_attach_partition, table_name, partition_name,
                         coalesce(''''||lower(boundaries)::text||'''', 'UNBOUNDED'),
                         coalesce(''''||upper(boundaries)::text||'''', 'UNBOUNDED')
                      );

        boundaries = tstzrange(upper(boundaries), upper(boundaries) + partition_interval, '[)');
        partition_name := to_char(lower(boundaries), partition_name_format);
    END LOOP;
END;
$dynsql$;

INSERT INTO log_entries (inserted)
SELECT '1998-01-01'::date + random() * (now() - '1998-01-01' + '1 month')
  FROM generate_series(1,100000);

EXPLAIN (ANALYZE, BUFFERS)
  SELECT to_char(inserted, 'YYYYMM'),
         count(*)
    FROM log_entries
GROUP BY 1;

CREATE TABLE rotate_hour (
    inserted timestamptz default now(),
    value text
)
PARTITION BY LIST (extract('hour' FROM (inserted at time zone 'UTC')));

DO LANGUAGE plpgsql $dynsql$
DECLARE
    sql_create_partition text := 'CREATE TABLE %I (LIKE %I INCLUDING ALL)';
    sql_attach_partition text := 'ALTER TABLE %I ATTACH PARTITION %I FOR VALUES IN (%L)';
    table_name text := 'rotate_hour';
    partition_name text;
BEGIN
    FOR i in 0..23 LOOP
        partition_name := table_name||'_'||lpad(i::text, 2, '0');
        EXECUTE format(sql_create_partition, partition_name, table_name);
        EXECUTE format(sql_attach_partition, table_name, partition_name, i);
        RAISE NOTICE '%', i;
    END LOOP;
END;
$dynsql$;

INSERT INTO rotate_hour (inserted)
SELECT '1998-01-01'::date + random() * (now() - '1998-01-01' + '1 month')
  FROM generate_series(1,100000);
