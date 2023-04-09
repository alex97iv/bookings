/*
Подготвительные миграции: V2, V3.

Описание:
Процедура которая осуществляет запись в БД информации о бронировании.

Входные параметры:
1. Номер билета (13 значная последовательность цифр);
2. Номер бронирования (6 значная последовательность цифр и букв);
3. Серия и номер паспорта пассажира через пробел (или номер свидетельства о рождении);
4. Полное имя пассажира (в английской транскрипции, без отчества);
5. Контактная информция в формате json (телефон - обязательно, email - опционально);
6. ID рейса (flight_id из таблицы flights);
7. Класс места в самолёте (по умолчанию - эконом).

Результат выполнения:
Информационное сообщение.

Допущения: 
1. в бронировании участвует 1 человек, одному билету соответствует один перелёт;
2. на вход функции поступает номер билета и бронирования (уникальный), который генерируется извне;
3. цена билета константа;
4. дата бронирования константа и равна bookings.now().
*/

CREATE PROCEDURE book_flight(ticket_no    	 char(13), 
							 book_ref 	  	 char(6), 
							 passenger_id 	 varchar(20), 
							 passenger_name  text, 
							 contact_data 	 jsonb, 
							 flight_id 		 int, 
							 fare_conditions varchar(10),
							 INOUT msg 		 text DEFAULT NULL) 
AS $$
DECLARE 
	seats_taken int;
	fcon_seats_num int;
	amount numeric;
	msg text;
BEGIN
	-- получение числа забронированных на рейсе мест
	SELECT count(*)
	  INTO seats_taken
	  FROM ticket_flights tf
	 WHERE tf.flight_id = book_flight.flight_id
	   AND tf.fare_conditions = book_flight.fare_conditions;

	-- отладка
	RAISE NOTICE 's1 compteled: seats_taken = %', seats_taken;

	-- получение числа мест данного класса для данной модели самолёта 
	SELECT seats_number
	  INTO fcon_seats_num
	  FROM aircraft_seats_number_mv smv
	 WHERE smv.fare_conditions = book_flight.fare_conditions
	   AND smv.aircraft_code = 
		   (SELECT aircraft_code
			  FROM flights f
			 WHERE f.flight_id = book_flight.flight_id);

	-- отладка
	RAISE NOTICE 's2 completed: fcon_seats_num = %', fcon_seats_num;

	IF seats_taken < fcon_seats_num THEN
			
		-- отладка
		RAISE NOTICE 'Проверка прошла успешно, места есть!';

		-- определяем стоимость билета
		CASE fare_conditions 
		 	WHEN 'Economy' THEN 
				amount = 4000;
		 	WHEN 'Business' THEN 
				amount = 7000;
		    ELSE 
				amount = 0;
		END CASE;
		
		INSERT INTO bookings(book_ref, book_date, total_amount)
		VALUES (book_flight.book_ref, bookings.now(), amount);

		INSERT INTO tickets(ticket_no, book_ref, passenger_id, passenger_name, contact_data)
		VALUES (book_flight.ticket_no, book_flight.book_ref, book_flight.passenger_id,
		 	   book_flight.passenger_name, book_flight.contact_data);
		
		INSERT INTO ticket_flights(ticket_no, flight_id, fare_conditions, amount)
		VALUES (book_flight.ticket_no, book_flight.flight_id, book_flight.fare_conditions, amount);

		msg = format(E'Вы успешно забронировали место на рейс № %s.\n' || 
					 E'Номер Вашего билета: %s.\n' || 
					 E'Номер бронирования: %s.\n' || 
					 E'Класс билета: %s.\n' ||  
					 E'Стоимость: %s.\n' ||
					 E'Будьте внимательны! Региcтрация на рейс начинается за 48 ч до вылета.',
		  	  		 book_flight.flight_id, book_flight.ticket_no, book_flight.book_ref, 
					 book_flight.fare_conditions, amount);
		ROLLBACK;
	ELSE	
		msg = format('К сожалению, все места указанного класса на рейс %s уже забронированы.\n
					 Укажите другой класс места и попробуйте снова.', book_flight.flight_id);	
	END IF;
	
	-- отладка
	RAISE NOTICE '%', msg;

END;
$$ LANGUAGE plpgsql;

/* TEST */

CALL book_flight(ticket_no 		 => '0005555000222', 
				 book_ref 		 => 'A123BC',
				 passenger_id 	 => '3915 099262',
				 passenger_name  => 'ALEXANDR IVANOV',
 				 contact_data 	 => '{"email": "iva111@postgrespro.ru", "phone": "+70340423946"}',
				 flight_id 		 => 5694,
				 fare_conditions => 'Economy');				

