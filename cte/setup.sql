CREATE TEMPORARY TABLE IF NOT EXISTS wide_table (
    wt_key   serial  primary key,
    wt_value json    not null
);

-- We record the temp schema name for later reuse
SELECT nspname AS my_temp_schema,
       format('%I.%I', nspname, 'wide_table') AS my_temp_table
  FROM pg_namespace
 WHERE oid = pg_my_temp_schema();
\gset

ALTER TABLE :my_temp_table ALTER COLUMN wt_value SET STORAGE plain;
TRUNCATE TABLE :my_temp_table;
CREATE INDEX ON :my_temp_table ((wt_key%100));


CREATE OR REPLACE FUNCTION :"my_temp_schema".large_json() RETURNS JSON LANGUAGE SQL AS
$body$
SELECT to_json(array_agg(md5(random()::text))) FROM generate_series(1,232);
$body$
VOLATILE;

INSERT
  INTO wide_table (wt_value)
SELECT :"my_temp_schema".large_json()
  FROM generate_series(1,100000);

ANALYZE :my_temp_table;

--DROP TABLE IF EXISTS :my_temp_table;
