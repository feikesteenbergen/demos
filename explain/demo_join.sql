\set ECHO queries
\echo

EXPLAIN
SELECT *
  FROM orders
  JOIN orderlines USING (orderid)
 WHERE orderid IN (12345,929,2823,1122,3998,23,-1,2);

\echo
\prompt 'Lets also ANALYZE this query' dummy
\echo

EXPLAIN ANALYZE
SELECT *
  FROM orders
  JOIN orderlines USING (orderid)
 WHERE orderid IN (12345,929,2823,1122,3998,23,-1,2);

\echo
\prompt 'Press return for a non Nested Loop example' dummy
\echo

EXPLAIN ANALYZE
SELECT *
  FROM orders
  JOIN orderlines USING (orderid)
;

\echo
\prompt 'Ok, so a hash join with about 2MB memory usage, what if we reduce the allowed memory?' dummy
\echo

SET work_mem TO '64kB';

EXPLAIN (ANALYZE ON, BUFFERS ON)
SELECT *
  FROM orders
  JOIN orderlines USING (orderid)
;

SET work_mem TO DEFAULT ;

