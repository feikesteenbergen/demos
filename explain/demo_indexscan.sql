\set ECHO queries

EXPLAIN
SELECT *
  FROM orders
 WHERE orderid IN (10872,4566,-11);
;

\echo
\prompt 'Press return for next example' dummy
\echo

EXPLAIN
  SELECT *
    FROM orders
ORDER BY orderid
;



\echo
\prompt 'Press return for next example' dummy
\echo

EXPLAIN
SELECT count(*)
  FROM orders
;

\echo
\prompt 'Why was that not an index scan?' dummy
\echo

\dt+ public.orders
\di+ public.orders_pkey

\echo
\prompt 'We will now create a wider table' dummy
\echo

ALTER TABLE public.orders ADD COLUMN dummy TEXT default (repeat(md5(random()::text), 200)) NOT NULL;
VACUUM ANALYZE public.orders;

\dt+ public.orders
\di+ public.orders_pkey

\echo
\prompt 'We have another look' dummy
\echo

EXPLAIN
SELECT count(*)
  FROM orders
;

\echo
\prompt 'Let take a look at a bit more detailed plan'
\echo

