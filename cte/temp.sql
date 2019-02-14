EXPLAIN ANALYZE
WITH RECURSIVE fibonacci (n, previous) AS (
    SELECT 1,
           0
    UNION ALL
    SELECT n+previous,
           n
      FROM fibonacci
     WHERE n < 40000000
)
SELECT count(*) 
  FROM pg_class;
