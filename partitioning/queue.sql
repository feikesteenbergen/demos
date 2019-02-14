CREATE TABLE q_test (
    id bigserial not null,
    inserted timestamptz default now(),
    leased_at timestamptz,
    message jsonb not null
)
PARTITION BY LIST (extract('hour' FROM (inserted at time zone 'UTC')));

CREATE TABLE q_test_0 ( LIKE q_test INCLUDING ALL);
ALTER TABLE q_test_0 ADD CONSTRAINT q_test_0_pkey PRIMARY KEY (id);
ALTER TABLE q_test_0 CLUSTER ON q_test_0_pkey;
ALTER TABLE q_test ATTACH PARTITION q_test_0 FOR VALUES IN (0,3,6,9,12,15,18,21);

CREATE TABLE q_test_1 ( LIKE q_test INCLUDING ALL);
ALTER TABLE q_test_1 ADD CONSTRAINT q_test_1_pkey PRIMARY KEY (id);
ALTER TABLE q_test_1 CLUSTER ON q_test_1_pkey;
ALTER TABLE q_test ATTACH PARTITION q_test_1 FOR VALUES IN (1,4,7,10,13,16,19,22);

CREATE TABLE q_test_2 ( LIKE q_test INCLUDING ALL);
ALTER TABLE q_test_2 ADD CONSTRAINT q_test_2_pkey PRIMARY KEY (id);
ALTER TABLE q_test_2 CLUSTER ON q_test_2_pkey;
ALTER TABLE q_test ATTACH PARTITION q_test_2 FOR VALUES IN (2,5,8,11,14,17,20,23);

INSERT INTO q_test (inserted, message)
SELECT '1998-01-01'::date + random() * (now() - '1998-01-01' + '1 month'),
  '"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"'::jsonb
  FROM generate_series(1,100000);

VACUUM ANALYZE VERBOSE q_test_0;
VACUUM ANALYZE VERBOSE q_test_1;
VACUUM ANALYZE VERBOSE q_test_2;

/* Workflow:
    - get EXLUSIVE LOCK on old_partition (blocks any DML)
    - CREATE new_partition (LIKE old_partition INCLUDING ALL)
    - INSERT INTO new_partition SELECT * FROM old_partition [ORDER BY id ASC?]
    - DETACH old_partition from table;
    - ATTACH new_partition to table;
    - DROP old_partition
    - PROFIT
/*
