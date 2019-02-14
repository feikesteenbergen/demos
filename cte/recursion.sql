\set ECHO queries
\echo
\prompt 'With recursion you can reference the CTE within the CTE, an example:' dummy
\echo
WITH RECURSIVE fibonacci (n, previous) AS (
    SELECT 1,
           0
    UNION ALL
    SELECT n+previous,
           n
      FROM fibonacci
     WHERE n < 300
)
SELECT array_agg(n ORDER BY n)
  FROM fibonacci;

\echo
\prompt 'Nice?' dummy
\prompt 'We create a table to play with, with people' dummy
\echo
DROP TABLE IF EXISTS pg_temp.people;
CREATE TABLE pg_temp.people (
    id integer primary key,
    name text,
    father integer references people(id),
    mother integer references people(id)
);

INSERT
  INTO pg_temp.people
VALUES (1, 'Grandmother Green', null, null),
       (2, 'Grandfather Green', null, null),
       (3, 'Grandmother Orange', null, null),
       (4, 'Grandfather Orange', null, null),
       (5, 'Father', 1, 2),
       (6, 'Mother', 3, 4),
       (7, 'Son', 5, 6),
       (8, 'Daughter', 5, 6);

\echo
\echo 'So now we have a very simple, multiple inheritance tree'
\prompt 'Who are the ancestors of Son?' dummy
\echo
WITH RECURSIVE ancestors (id, name, father, mother, level) AS (
    SELECT id,
           name,
           father,
           mother,
           0
      FROM pg_temp.people
     WHERE name = 'Son'
     UNION ALL
    SELECT p.id,
           p.name,
           p.father,
           p.mother,
           level+1
      FROM ancestors AS a
      JOIN pg_temp.people AS p ON (a.father = p.id OR a.mother = p.id)
)
SELECT *
  FROM ancestors
 WHERE level>0;
