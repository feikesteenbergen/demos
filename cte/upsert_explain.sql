\i prepare_upsert.sql

EXPLAIN ANALYZE
WITH new_values (new_key, new_value) AS (
    VALUES
        ('a','New value for a'),
        ('z','New value for z')
),  updated AS (
    UPDATE pg_temp.kv
       SET value=new_value
      FROM new_values
     WHERE key=new_key
 RETURNING kv.*
),  inserted AS (
    INSERT
      INTO pg_temp.kv (key, value)
    SELECT new_key,
           new_value
      FROM new_values
 LEFT JOIN updated ON (key=new_key)
     WHERE updated.key IS NULL
 RETURNING *
)
SELECT *
  FROM pg_temp.kv;

