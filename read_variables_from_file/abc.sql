/* This script is meant to read a specific file and load its contents into
  a named variable as a VALUES list, see:
       http://www.postgresql.org/docs/current/static/sql-values.html

  This named variable can than be used to query or join against in future queries of
  the psql session.

  The goal of this exercise is that you are able to write queries that can reference
  values that are stored at the client side, without any write-access on the
  connected PostgreSQL database. This also means this script can be used to
  query read-only replica's.


  Usage:

  \set variables_source FILE
  \set variables_target NAME
  \i load_variables_source.sql

  After this the variable NAME can be used in your session, for example:

        => \set variables_source continents.csv
        => \set variables_target continents
        => \i load_variables_source.sql
        => :continents;
            column1    | column2
        ---------------+----------
         Africa        | 30250380
         Antarctica    | 13132101
         Asia          | 31881008
         Europe        | 23049132
         North America | 24214472
         Oceania       | 8564294
         South America | 17864926
        (7 rows)
        => -- OR as a CTE:
        => WITH continents (continent, surfacearea) AS (:continents)
        -> SELECT * FROM continents;
           continent   | surfacearea
        ---------------+-------------
         Africa        | 30250380
         Antarctica    | 13132101
         Asia          | 31881008
         Europe        | 23049132
         North America | 24214472
         Oceania       | 8564294
         South America | 17864926
        (7 rows)

 Limitations:

   SIZE
     Although no limit is enforced, it would be wise to only consider relative
     small files for processing as the contents of the file will be sent over the network
     at least 4 times:
       - The contents of the file will be copied to the server for processing
       - the processed result is sent back to the client
       - this is done *twice*, as \gset executes the query again
       - every time you reference the variable the processed result is sent to the server

   CSV
     It is basically a very simple csv parser:
       - every line is a new row
       - every , (comma) is a field separator
       - every column is treated as text
*/


-- We determine the OS of psql, to know what device is the null device
SELECT CASE
            WHEN :'VERSION' ~ 'compiled by Visual C'
            THEN 'NUL'
            ELSE '/dev/null'
       END AS nulldevice
\gset

-- Warn windows users about the warning they will receive
SELECT 'You will receive a warning about ''cat'' not existing. You can ignore this warning'
 WHERE :'nulldevice' = 'NUL';

-- Disable output, as not to clutter the console output
\o :nulldevice
-- to enable access to the variable from inside the backticks
-- we set an environment variable with the file name
\setenv PSQLLOADFILE :variables_source
-- Load the full file into a variable
-- We use the logical || to be able to be run on Windowish and Linux-like OS'es
\set filecontents `cat "${PSQLLOADFILE}" || type "%PSQLLOADFILE%"`
-- We could use a CSV parser at this stage, this is a poor solution relying on comma's only used as seperators
SELECT format('(VALUES (%s))',
                    array_to_string(
                        array_agg(fields),
                        '),('
                    )
            )   AS :"variables_target",
       count(*) AS variables_loaded
  FROM (
    SELECT array_to_string(
                (SELECT array_agg(format('%L', unnest))
                   FROM unnest(string_to_array(sub.line,','))
                ), ',')
      FROM regexp_split_to_table(regexp_replace(:'filecontents'::text, '\s+$', ''), '[\n\r]+') AS sub(line)
    ) AS lines(fields);
\gset
-- Reenable console output
\o
-- Report something back to the client for validation
SELECT :'variables_loaded' AS variables_loaded
\unset filecontents
