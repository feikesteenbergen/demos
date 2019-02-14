EXPLAIN ANALYZE
WITH my_cte AS (
    SELECT *
      FROM :my_temp_table
     WHERE wt_key%20 = 0
)
SELECT count(*)
  FROM my_cte;
