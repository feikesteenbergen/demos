Parallel query
==============
One of the most anticipated features of PostgreSQL for 9.6 would be Parallel Query. In its current state
it is not of much value yet, but having the groundwork committed means we can probably expect a lot of
new features showing up in later releases.


Let's create a demo table to do our stuff against:
```sql
CREATE TABLE customer AS
SELECT c_id,
       substr(md5(random()::text), 5, (5+random()*20)::int) AS c_first_name,
       '1900-01-01'::date + (c_id/274) AS c_born,
       false as c_is_fraud
  FROM generate_series(1,(10^7)::int) AS series(c_id);
ALTER TABLE customer ADD PRIMARY KEY (c_id);
ANALYZE customer;
SET max_parallel_degree TO 0;
```

So, how big is the table now? (psql only)
```sql
\dt+ customer
```

```sql
SELECT setting, source FROM pg_settings WHERE name = 'max_parallel_degree';
```

```sql
SELECT avg(c_id),
       sum(c_id)
  FROM customer;
```

```sql
SET max_parallel_degree TO 1;
```


Count all customers who are having their birtday today
```sql
SELECT count(*)
  FROM customer
 WHERE to_char(c_born, 'MM-DD') = to_char(current_date, 'MM-DD');
```

Since 9.5 we already have BRIN, which really helps on certain distributions of values, think of monotone increasing
dates (eventlog?)
```sql
SET max_parallel_degree TO 0;

EXPLAIN ANALYZE
SELECT count(*)
  FROM customer
 WHERE c_born < '1920-01-01';

SET max_parallel_degree TO 1;

EXPLAIN ANALYZE
SELECT count(*)
  FROM customer
 WHERE c_born < '1920-01-01';

CREATE INDEX ON customer USING BRIN (c_born);
EXPLAIN ANALYZE
SELECT count(*)
  FROM customer
 WHERE c_born < '1920-01-01';
```

Does an update benefit from this parallel stuff?
```sql
SET max_parallel_degree TO 0;

EXPLAIN ANALYZE
UPDATE customer
   SET c_is_fraud = true
 WHERE to_char(c_born, 'MM-DD') = to_char(current_date, 'MM-DD');
```

```
CREATE TABLE TEST (
    id serial,
    text character varying
)
WITH (fillfactor=10);
