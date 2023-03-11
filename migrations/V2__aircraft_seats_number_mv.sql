CREATE MATERIALIZED VIEW aircraft_seats_number_mv AS
SELECT aircraft_code,
	   fare_conditions,
	   count(seat_no) AS seats_number
  FROM seats 
 GROUP BY aircraft_code, fare_conditions 
 ORDER BY aircraft_code, fare_conditions;
