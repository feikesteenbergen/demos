\i table_car.sql

\set variables_file   car_ids.list
\set variables_target car_ids
\i load_variables_file.sql

  SELECT extract(year FROM delivered) AS year,
         sum(list_price)              AS list_price,
         sum(value)                   AS value
    FROM car
   WHERE car_id IN (:car_ids)
GROUP BY extract(year FROM delivered);
