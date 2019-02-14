\i prepare_upsert.sql

DELETE
  FROM pg_temp.kv
 WHERE key = 'z';

WITH new_values (new_key, new_value) AS (
    VALUES
        ('a','Newer value for a'),
        ('z','Newer value for z')
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

SELECT *
  FROM pg_temp.kv;

