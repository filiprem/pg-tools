CREATE EXTENSION ddl_versioning;

SELECT object_id,object_type,object_identity FROM ddl_versioning_object;
SELECT object_id,version_id,object_definition FROM ddl_versioning_version;

-- initial version of table
CREATE TABLE test (id int4 PRIMARY KEY, payload text);

-- initial version of function
CREATE FUNCTION test(int) RETURNS text LANGUAGE sql AS 'SELECT payload FROM test WHERE id=$1';

-- amended table (should create version 2)
ALTER TABLE test ADD extra boolean;

-- new index
CREATE INDEX test_extra_idx ON test (extra) WHERE id<>1;

-- amended function (should create version 2)
CREATE OR REPLACE FUNCTION test(int) RETURNS text LANGUAGE sql AS 'SELECT payload FROM test WHERE id=$1 AND extra';

SELECT object_id,object_type,object_identity FROM ddl_versioning_object ORDER BY 1;
SELECT object_id,version_id,object_definition FROM ddl_versioning_version ORDER BY 1,2;
