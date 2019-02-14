-- We load the psql variable into an environment variable,
-- to enable access to the variable from inside the backticks
\setenv PSQLLOADFILE :variables_file
-- Load the full file into a variable
\set filecontents `cat "${PSQLLOADFILE}"`
-- Disable output, as not to clutter the console output
--\o /dev/null
WITH myrows (fields) AS (
    SELECT array_to_string((SELECT array_agg(format('%L', unnest))
                             FROM unnest(string_to_array(sub.line,','))),
                           ',')
                           
      FROM regexp_split_to_table(regexp_replace(:'filecontents'::text, '\s+$', ''), '[\n\r]+') AS sub(line)
)
SELECT format('(VALUES (%s)) AS %I',
                    array_to_string(
                        array_agg(fields),
                        '),('
                    ),
                    :'variables_target'
            )   AS :"variables_target",
       count(*) AS variables_loaded
  FROM myrows;
\gset
-- Reenable console output
\o
-- Report something back to the client for validation
SELECT :'variables_loaded' AS variables_loaded
\unset filecontents
                
