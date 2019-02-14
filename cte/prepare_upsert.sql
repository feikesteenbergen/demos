\set ECHO none
DROP TABLE IF EXISTS pg_temp.kv;
CREATE TEMPORARY TABLE kv (key text primary key, value text);
INSERT
  INTO kv
VALUES ('a', 'Value for a'),
       ('b', 'Value for b');

\set ECHO queries
