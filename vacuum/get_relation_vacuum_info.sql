DROP FUNCTION vacuum_information(regclass);
CREATE OR REPLACE FUNCTION vacuum_information(regclass,
    OUT oid oid,
    OUT relname name,
    OUT reltuples real,
    OUT relpages int,
    OUT reloptions jsonb,
    OUT relkind char,
    OUT n_live_tup bigint,
    OUT n_dead_tup bigint,
    OUT n_mod_since_analyze bigint,
    OUT last_any_vacuum timestamptz,
    OUT last_any_analyze timestamptz,
    OUT vacuum_threshold real,
    OUT analyze_threshold real,
    OUT needs_vacuum boolean,
    OUT needs_analyze boolean
)
LANGUAGE plpgsql
AS
$BODY$
BEGIN
    SELECT jsonb_object_agg(name, setting)
      INTO reloptions
      FROM pg_settings
     WHERE name LIKE 'autovacuum\_%';

    SELECT pc.oid,
           pc.relname,
           pc.reltuples,
           pc.relpages,
           vacuum_information.reloptions||coalesce(opts.reloptions, '{}'),
           pc.relkind,
           psut.n_live_tup,
           psut.n_dead_tup,
           psut.n_mod_since_analyze,
           greatest(last_vacuum, last_autovacuum),
           greatest(last_analyze, last_autoanalyze)
      INTO oid,
           relname,
           reltuples,
           relpages,
           reloptions,
           relkind,
           n_live_tup,
           n_dead_tup,
           n_mod_since_analyze,
           last_any_vacuum,
           last_any_analyze
      FROM pg_class pc
CROSS JOIN LATERAL (
                SELECT jsonb_build_object(split_part(unnest, '=', 1),
                                          split_part(unnest, '=', 2))
                  FROM unnest(pc.reloptions)
           ) AS opts(reloptions)
      JOIN pg_stat_user_tables psut ON (pc.oid = psut.relid)
     WHERE pc.oid = $1;

    vacuum_threshold := (reloptions->>'autovacuum_vacuum_threshold')::float
                        +
                        (reloptions->>'autovacuum_vacuum_scale_factor')::float*reltuples;
    analyze_threshold := (reloptions->>'autovacuum_analyze_threshold')::float
                        +
                        (reloptions->>'autovacuum_analyze_scale_factor')::float*reltuples;
    needs_vacuum := vacuum_threshold < n_dead_tup;
    needs_analyze := analyze_threshold < n_mod_since_analyze;
END;
$BODY$;
