/* 
DESCRIPTION:
функция для клиентского приложения, которая 
выводит таблицу содержащую информацию о рейсах, 
доступных для бронирования и соответствующих начальным условиям.

Входные параметры: 
1. город отправления, 
2. город прибытия,
3. начальная дата и время диапазона отправления, 
4. конечная дата и время диапазона отправления, 
5. код аэропорта убытия - опционально (по умолчанию отображаются все аэропорты),
6. код аэропорта прибытия - опционально (по умолчанию отображаются все аэропорты).

Результат выполнения:
1. Дата и время отправления рейса (с часовым поясом),
2. Дата и время прибытия рейса (с часовым поясом),
3. Код аэропорта убытия,
4. Код аэропорта прибытия,
5. Время в полёте.
*/

DROP FUNCTION IF EXISTS available_flights(text, text, timestamptz, timestamptz, char(3), char(3));

CREATE FUNCTION available_flights(dep_city 		 		 text, 
   							      arr_city 			 	 text, 
   						          dep_start 			 timestamptz,
   					              dep_end				 timestamptz, 
   							      INOUT dep_airport_code char(3) DEFAULT NULL,
   							      INOUT arr_airport_code char(3) DEFAULT NULL,
   							      OUT dep_time 	 		 timestamptz, 
   							      OUT arr_time 		 	 timestamptz,
   							      OUT flight_time 		 interval)
RETURNS SETOF record
AS $$
	BEGIN
		RETURN QUERY 
		SELECT departure_airport, 
		 	   arrival_airport,
		  	   scheduled_departure,
		  	   scheduled_arrival,
		  	   (scheduled_arrival - scheduled_departure) AS flight_time
		  FROM flights_v fv
		 WHERE scheduled_departure >= dep_start
		   AND scheduled_departure <= dep_end
		   AND fv.departure_city = dep_city
		   AND fv.arrival_city = arr_city
 		   AND departure_airport LIKE coalesce(dep_airport_code, '%')
 		   AND arrival_airport LIKE coalesce(arr_airport_code, '%')
		   AND status = 'Scheduled'
		 ORDER BY scheduled_departure; 
	END;
$$ LANGUAGE plpgsql VOLATILE;

/* TEST */

SELECT *
  FROM available_flights(dep_city 		  => 'Москва', 
   					  	 arr_city 		  => 'Санкт-Петербург', 
   					  	 dep_start 		  => '2017-09-10 18:00:00+03', 
   					  	 dep_end 		  => '2017-09-15 18:00:00+03', 
   					  	 dep_airport_code => 'VKO',
   					  	 arr_airport_code => 'LED');
