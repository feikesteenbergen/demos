\i prepare_upsert.sql

INSERT
  INTO pg_temp.kv (key, value)
VALUES ('a','New value for a'),
       ('z','New value for z')
ON CONFLICT (key)
DO UPDATE SET value=EXCLUDED.value;

SELECT *
  FROM pg_temp.kv;
