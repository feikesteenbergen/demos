-- We load the psql variable into an environment variable,
-- to enable access to the variable from inside the backticks
\setenv PSQLLOADFILE :variables_file
-- Load the full file into a variable
\set filecontents `cat "${PSQLLOADFILE}"`
-- Disable output, as not to clutter the console output
\o /dev/null
SELECT array_to_string(array_agg(format('%L', field)), ',') AS :"variables_target",
       count(*) AS variables_loaded
  FROM regexp_split_to_table(regexp_replace(:'filecontents'::text, '\s+$', ''), '[\n\r]+') AS sub(field);
\gset
-- Reenable console output
\o
-- Report something back to the client for validation
SELECT :'variables_loaded' AS variables_loaded
\unset filecontents
                
