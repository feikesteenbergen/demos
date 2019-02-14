\set ECHO queries

EXPLAIN ANALYZE
WITH troublesome_query AS (
    SELECT relname,
           nspname,
           relkind
      FROM pg_class AS pc
 LEFT JOIN pg_namespace AS pn ON (pc.relnamespace=pn.oid)
 LEFT JOIN pg_attribute AS pa ON (pa.attrelid=pc.oid)
 LEFT JOIN pg_stats AS ps ON (ps.schemaname=pn.nspname AND ps.tablename = pc.relname AND ps.attname = pa.attname)
 LEFT JOIN pg_index AS pi ON (pi.indexrelid=pc.oid)
   WHERE tablename='pg_roles'
     AND relkind='r'
)
SELECT *
  FROM troublesome_query
 WHERE relname='pg_roles'
   AND relkind='r';
