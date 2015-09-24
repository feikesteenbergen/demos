DO
$$
BEGIN

IF NOT EXISTS (SELECT 1
                 FROM pg_class      pc
                 JOIN pg_namespace  pn ON (pc.relnamespace=pn.oid)
                WHERE pn.nspname = current_schema
                  AND relkind='r'
                  AND relname='car')
THEN
    RAISE WARNING 'Creating table car and filling it with some values';
    CREATE TABLE car (
        car_id      serial        PRIMARY KEY,
        list_price  integer       not null,
        value       integer       not null default 1,
        delivered   date
    );

    INSERT
      INTO car (list_price, value, delivered)
    SELECT list_price,
           100+(list_price*random()-100),
           '2008-01-01'::date + random() * interval '8 years'
      FROM (SELECT random()*50000+10000 FROM generate_series(1,200)) AS series(list_price);

    DELETE
      FROM car
     WHERE random() < 0.6;
END IF;

END;
$$
