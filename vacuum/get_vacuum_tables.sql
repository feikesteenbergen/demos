WITH vacuum_options AS (
    SELECT jsonb_object_agg(name, setting) AS global_options
      FROM pg_settings
     WHERE name LIKE 'autovacuum%threshold'
        OR name LIKE 'autovacuum%scale_factor'
),  all_relations AS (
    SELECT oid,
           relname,
           relkind,
           nspname,
           reltuples,
           global_options || coalesce(opts.reloptions, '{}') AS reloptions,
           reltoastrelid,
           pg_stat_get_dead_tuples(oid) AS n_dead_tuples,
           pg_stat_get_mod_since_analyze(oid) AS n_mod_since_analyze,
           -- We want to know the "physical" order in which this entry occurs
           row_number() over (ORDER BY pc.ctid)
      FROM pg_class AS pc
 LEFT JOIN LATERAL
           (SELECT oid,
                   jsonb_object_agg(split_part(unnest, '=', 1), split_part(unnest, '=', 2))
              FROM unnest(pc.reloptions)
             WHERE unnest like 'autovacuum\_%') AS opts(oid, reloptions)
           ON (pc.oid = opts.oid)
      JOIN pg_namespace pn ON (pc.relnamespace = pn.oid)
CROSS JOIN vacuum_options
     WHERE relkind IN ('r', 'm', 't')
-- Toast relations take the values from the corresponding table
),  toast_relations AS (
    SELECT t.oid,
           t.relname,
           t.relkind,
           t.nspname,
           t.reltuples,
           parent.reloptions || coalesce(t.reloptions, '{}') AS reloptions,
           t.reltoastrelid,
           t.n_dead_tuples,
           t.n_mod_since_analyze,
           t.row_number
      FROM all_relations AS t
      JOIN all_relations AS parent ON (t.oid = parent.reltoastrelid)
     WHERE t.relkind = 't'
), expanded_relations AS (
   SELECT *
     FROM all_relations AS ar
    WHERE relkind IN ('r', 'm')
UNION ALL
   SELECT *
     FROM toast_relations AS td
    WHERE relkind = 't'
), base_data AS (
    SELECT relname,
           nspname,
           reltuples,
           n_dead_tuples,
           n_mod_since_analyze,
           row_number,
           (reloptions->>'autovacuum_vacuum_threshold')::int + reltuples * (reloptions->>'autovacuum_vacuum_scale_factor')::float AS vacuum_threshold,
           (reloptions->>'autovacuum_analyze_threshold')::int + reltuples * (reloptions->>'autovacuum_analyze_scale_factor')::float AS analyze_threshold
     FROM expanded_relations
)
SELECT *,
       vacuum_threshold < n_dead_tuples AS needs_vacuum,
       analyze_threshold < n_mod_since_analyze AS needs_analyze
  FROM base_data
 WHERE (vacuum_threshold < n_dead_tuples
       OR analyze_threshold < n_mod_since_analyze)
   AND nspname NOT IN ('pg_toast', 'pg_catalog');
/*
WITH global_option (parameter, setting) AS (
    SELECT name,
           setting
      FROM pg_settings
     WHERE NAME like 'autovacuum_%scale%'
           OR
           NAME like 'autovacuum_%thresh%'
)   ,   table_info AS (
    SELECT nspname,
           relname,
           reltuples,
           pg_stat_get_dead_tuples(pc.oid) AS dead_tuples
           reloptions
      FROM pg_class AS pc
      JOIN pg_namespace AS pn ON (pc.relnamespace = pn.oid)
     WHERE relkind = 'r'
)
    regexp_split_to_arrayregexp_split_to_arraySELECT table_info.*
           pc.reltuples,
           pg_stat_get_dead_tuples(pc.oid) AS dead_tuples,
           table_option.*,
           global_option.*,
           CASE global_option.parameter
                WHEN 'autovacuum_freeze'
                    THEN 'beer'
                    ELSE 'coke'
           END
      FROM pg_class pc
      JOIN pg_namespace pn
           ON (pc.relnamespace=pn.oid)
CROSS JOIN global_option
 LEFT JOIN LATERAL (
                SELECT pc.oid,
                       split_part(unnest(pc.reloptions), '=', 1),
                       split_part(unnest(pc.reloptions), '=', 2)
                ) AS table_option(oid, parameter, setting)
           ON (pc.oid = table_option.oid AND global_option.parameter = table_option.parameter)
     WHERE relkind='r'
       AND relname = 'def'
  ORDER BY nspname, relname, 3;
*/
