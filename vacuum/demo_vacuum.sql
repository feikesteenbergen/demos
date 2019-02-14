/* Author: Feike Steenbergen

It requires:
* psql as a client >= 9.6 (It uses \gexec)
* PostgreSQL server >= 9.6 (It requires pg_stat_progress_vacuum)

This demo is unsafe to run on a production cluster.
During the demo we restart the cluster multiple times to enforce different parameter settings.

The demo does use its own schema and tables, therefore it should not interfere with any data in
your current database. However, no warranties are given.

*/

\set QUIET on

SET client_min_messages TO ERROR;

-- We want to stop on any error
\set ON_ERROR_STOP on
\set DEMO_SCHEMA vacuum_demo_schema

\pset pager off
\timing off

DROP SCHEMA IF EXISTS :"DEMO_SCHEMA" CASCADE;
CREATE SCHEMA :"DEMO_SCHEMA";
SET search_path TO :"DEMO_SCHEMA";

CREATE FUNCTION :"DEMO_SCHEMA".assert_equals(a text, b text, message text default null, OUT result text)
LANGUAGE plpgsql 
AS $BODY$
BEGIN
  IF NOT (a = b) THEN
  	RAISE SQLSTATE 'P0004' USING
  		MESSAGE = coalesce(message, format('%s is not equal to %s', a, b));
  END IF;
  result := 'ok';
END;
$BODY$;


\echo   '*** WARNING *** This demo causes restarts and load on the connected database.'
\echo   '                You should *NOT* run this on a production environment.'
\echo
\echo   'Do you wish to continue? (yes/no) ' dummy

SELECT * FROM assert_equals('yes', :'dummy', 'Aborted by user');


-- Utility function to execute OS commands and capture its output
CREATE UNLOGGED TABLE :"DEMO_SCHEMA".stdout (id serial, t text);
CREATE FUNCTION :"DEMO_SCHEMA".command(text, OUT stdout text[], OUT exitcode int)
LANGUAGE plpgsql
AS $BODY$
DECLARE
	line text;
BEGIN
	TRUNCATE stdout;
	ALTER SEQUENCE stdout_id_seq restart;

	EXECUTE format($$COPY stdout (t) FROM PROGRAM '%s; echo $?'$$, $1); 

	DELETE
	  FROM stdout
	 WHERE id = (SELECT max(id) FROM stdout)
	 RETURNING t::int
	      INTO exitcode;

	SELECT array_agg(t ORDER BY id)
	  INTO stdout
	  FROM stdout;
END;
$BODY$
SET search_path = :"DEMO_SCHEMA";

CREATE FUNCTION :"DEMO_SCHEMA".read_file(text)
RETURNS TABLE (line_no int, line text)
LANGUAGE plpgsql
AS $BODY$
BEGIN
	PERFORM command(format('cat %s', $1));
	RETURN QUERY
	SELECT id,
		   t
	  FROM stdout;
END;
$BODY$
SET search_path = :"DEMO_SCHEMA";

CREATE FUNCTION :"DEMO_SCHEMA".postmaster_info(OUT pid int, OUT path text)
LANGUAGE plpgsql
AS $BODY$
BEGIN
	  SELECT line
	    INTO pid    
	    FROM read_file('postmaster.pid')
	ORDER BY line_no ASC LIMIT 1;

	  SELECT stdout[1]
	    INTO path
	    FROM command(format('dirname $(readlink /proc/%s/exe)', pid));
END;
$BODY$
SET search_path = :"DEMO_SCHEMA";

CREATE FUNCTION :"DEMO_SCHEMA".pg_ctl(VARIADIC args text[], OUT stdout text[], OUT exitcode int)
LANGUAGE plpgsql
AS $BODY$
DECLARE
	quoted_args text;
BEGIN
	SELECT string_agg(format('"%s"', u), ' ')
	  INTO quoted_args
	  FROM unnest(args) AS s(u);

	SELECT c.stdout,
		   c.exitcode
      INTO stdout,
           exitcode
      FROM command(format('"%s/pg_ctl" %s', (SELECT path FROM postmaster_info()), quoted_args)) AS c;
END;
$BODY$

SET client_min_messages TO WARNING;
\set QUIET off

SELECT line AS postmaster_pid
  FROM read_file('postmaster.pid')
ORDER BY line_no ASC LIMIT 1
\gset

SELECT :'postmaster_pid';
