create keyspace CityInfo with replication = {'class' : 'SimpleStrategy', 'replication_factor':2};


use CityInfo;


CREATE TABLE cities (
 id int,
 name text,
 country text,
 PRIMARY KEY(id)
);

INSERT INTO cities(id,name,country) VALUES (1,'Karachi','Pakistan');
INSERT INTO cities(id,name,country) VALUES (2,'Lahore','Pakistan');
INSERT INTO cities(id,name,country) VALUES (3,'Dubai','UAE');
INSERT INTO cities(id,name,country) VALUES (4,'Berlin','Germany');


select * from cities;

exit;

