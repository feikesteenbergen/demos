\set ECHO queries

\prompt 'EXPLAIN will parse, the query, rewrite it into a query tree and display the query plan' dummy
\echo
EXPLAIN
SELECT 1
;

\echo
\prompt 'EXPLAIN ANALYZE will parse, rewrite, plan AND execute the query, displaying the plan and statistics' dummy
\echo
EXPLAIN ANALYZE
SELECT 1
;

\echo
\prompt 'EXPLAIN has a lot more options, which are useful when diving deeper into a query' dummy
\echo
\h EXPLAIN

\echo
\prompt '' dummy
\echo 'For example information about the IO subsystem'

EXPLAIN (ANALYZE ON, BUFFERS ON)
SELECT *
  FROM public.customers;
