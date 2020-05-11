create keyspace Test1_keyspace with replication = {'class' : 'SimpleStrategy', 'replication_factor':2};

use Test1_keyspace;

CREATE TABLE Test1_table (
  id int,
  v1 text,
  v2 text,
  PRIMARY KEY(id)
);

INSERT INTO Test1_table(id,v1,v2) VALUES (1,'a','aa');
INSERT INTO Test1_table(id,v1,v2) VALUES (2,'b','ab');
INSERT INTO Test1_table(id,v1,v2) VALUES (3,'c','cc');
INSERT INTO Test1_table(id,v1,v2) VALUES (4,'d','dd');
INSERT INTO Test1_table(id,v1,v2) VALUES (5,'e','ee');

select * from Test1_table;

exit;
