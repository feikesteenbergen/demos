\set ECHO queries

\i recursion.sql

\echo
\prompt '================ We can mimick an upsert using a CTE like this one' dummy
\echo
\i upsert.sql
\echo
\prompt 'Oops, what happened?' dummy
\echo
\prompt 'It has got to do with visibility of the tuples touched by the CTE' dummy
TRUNCATE pg_temp.kv;
INSERT
  INTO kv
VALUES ('a', 'Value for a'),
       ('b', 'Value for b');
\i upsert_explain.sql
\echo
\prompt 'So, how do we write one that does work?' dummy
\echo
\i upsert2.sql
\echo
\prompt 'But wait, this can be better right: Bring on 9.5!' dummy
\echo
\i upsert_new.sql
