\set ECHO queries
\echo

\echo
\prompt 'Lets create a play table' dummy
\echo

CREATE TEMPORARY TABLE IF NOT EXISTS my_demo_table (
    id integer PRIMARY KEY,
    value text,
    inserted_by text NOT NULL,
    inserted timestamptz NOT NULL DEFAULT current_timestamp
);
TRUNCATE pg_temp.my_demo_table;


\echo
\prompt 'This is our bulk statement' dummy
\echo

PREPARE my_demo_bulk_statement AS
INSERT INTO my_demo_table (id, value, inserted_by)
SELECT *
  FROM json_to_recordset($1) AS s(id integer, value text, inserted_by text)
ON CONFLICT (id) DO
UPDATE SET value = EXCLUDED.value,
           inserted_by = EXCLUDED.inserted_by
RETURNING xmin, xmax, *;

\echo
\prompt 'We try some stuff'
\echo

EXECUTE my_demo_bulk_statement($jsondoc$

[
  {
    "value": "a",
    "inserted_by": "John",
    "id": 1
  },
  {
    "value": "b",
    "inserted_by": "Mike",
    "id": "2"
  }
]

$jsondoc$);

\echo
\prompt 'And some more' dummy
\echo

EXECUTE my_demo_bulk_statement($jsondoc$

[
  {
    "value": "c",
    "inserted_by": "John",
    "id": 2
  },
  {
    "value": "d",
    "inserted_by": "Joseph",
    "id": "3"
  }
]

$jsondoc$);
