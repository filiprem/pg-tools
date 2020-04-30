pgboom
======

The `pgboom` program manipulates Postgres metadata.

It can extract (**`explode`**) object metadata (ie., database schema) from PostgreSQL
database to directory of flat SQL files, and vice versa (**`implode`**).

Each db object goes into separate file, `DIR/OBJECT-CLASS/SCHEMA-NAME/OBJECT-NAME.sql`.

Example directory representing a pgbench database initialized with `pgbench -i --foreign-keys`:
```
/tmp/test/PRIMARY_KEY/public/pgbench_accounts_pkey.sql
/tmp/test/PRIMARY_KEY/public/pgbench_tellers_pkey.sql
/tmp/test/PRIMARY_KEY/public/pgbench_branches_pkey.sql
/tmp/test/SCHEMA/public/public.sql
/tmp/test/TABLE/public/pgbench_tellers.sql
/tmp/test/TABLE/public/pgbench_history.sql
/tmp/test/TABLE/public/pgbench_branches.sql
/tmp/test/TABLE/public/pgbench_accounts.sql
/tmp/test/CONSTRAINT/public/pgbench_accounts_bid_fkey.sql
/tmp/test/CONSTRAINT/public/pgbench_history_bid_fkey.sql
/tmp/test/CONSTRAINT/public/pgbench_history_aid_fkey.sql
/tmp/test/CONSTRAINT/public/pgbench_tellers_bid_fkey.sql
/tmp/test/CONSTRAINT/public/pgbench_history_tid_fkey.sql
```

The `pgboom` program can also compare (**`diff`**) existing database to directory, producting a report of differences.

It can also concatenate (**`cat`**) directory contents into single SQL file.


Usage
-----

```
usage: pgboom [-h]
              [--Class {SCHEMA,EXTENSION,FUNCTION,AGGREGATE,SEQUENCE,PARTITIONED_TABLE,TABLE,SEQUENCE_OWNED_BY,PRIMARY_KEY,CONSTRAINT,PARTITIONED_INDEX,INDEX,VIEW}]
              [--Schema SCHEMA] [--Object OBJECT] [--File FILE] [--debug]
              ACTION DSN DIR

The pgboom utility manipulates Postgres metadata.

For details, see https://github.com/filiprem/pg-tools/tree/master/pgboom.

positional arguments:
  ACTION                explode: Saves object definitions (SQL CREATE statements) from Postgres to directory.
                            Each object goes into separate file, DIR/<CLASS>/<schema>/<object>.sql.
                        
                        implode: Loads object definitions from directory to Postgres.
                            Does not overwrite any pre-existing objects.
                        
                        diff: Compares object definitions between database and directory, using system `diff` command.
                            The directory should have same structure as produced by `pgboom explode`.
                            Results are saved to --File, in context diff format.
                        
                        cat: Does the same as implode, but concatenates into --File, not database.
                        
                        test: Performs a built-in test (for developers).
  DSN                   PostgreSQL data source in 'key=value' format
  DIR                   Destination/source directory

optional arguments:
  -h, --help            show this help message and exit
  --Class {SCHEMA,EXTENSION,FUNCTION,AGGREGATE,SEQUENCE,PARTITIONED_TABLE,TABLE,SEQUENCE_OWNED_BY,PRIMARY_KEY,CONSTRAINT,PARTITIONED_INDEX,INDEX,VIEW}, -C {SCHEMA,EXTENSION,FUNCTION,AGGREGATE,SEQUENCE,PARTITIONED_TABLE,TABLE,SEQUENCE_OWNED_BY,PRIMARY_KEY,CONSTRAINT,PARTITIONED_INDEX,INDEX,VIEW}
                        Type of objects to extract/load
  --Schema SCHEMA, -S SCHEMA
                        Database schema name regex
  --Object OBJECT, -O OBJECT
                        Database object name regex
  --File FILE, -F FILE  Output file for `cat` and `diff` actions
  --debug, --verbose, -v
                        Set verbose debugging on

```

Examples
--------

Export all objects from database into directory:
```
$ pgboom explode 'host=localhost port=5432 dbname=test' /tmp/test
2020-04-27 23:42:27 INFO explode finished, stats: {'SCHEMA': 1, 'EXTENSION': None, 'FUNCTION': None, 'AGGREGATE': None, 'SEQUENCE': None, 'TABLE': 4, 'SEQUENCE_OWNED_BY': None, 'PRIMARY_KEY': 3, 'CONSTRAINT': 5, 'INDEX': None, 'VIEW': None}
```

Import directory into database, filtering by schema and object name:
```
$ pgboom implode 'dbname=test' /tmp/test --Class TABLE --Schema public --Object '^pgbench' --debug
2020-04-27 23:43:36 DEBUG main pgboom implode starting
2020-04-27 23:43:36 DEBUG main testing database connection
2020-04-27 23:43:37 DEBUG main connection OK: user=filip, db=test, version=PostgreSQL 12.2 (Ubuntu 12.2-2.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
2020-04-27 23:43:37 DEBUG implode_objects processing TABLE definitions
2020-04-27 23:43:37 DEBUG implode_objects processing /tmp/test/TABLE/public/pgbench_tellers.sql
2020-04-27 23:43:37 DEBUG implode_objects processing /tmp/test/TABLE/public/pgbench_history.sql
2020-04-27 23:43:37 DEBUG implode_objects processing /tmp/test/TABLE/public/pgbench_branches.sql
2020-04-27 23:43:37 DEBUG implode_objects processing /tmp/test/TABLE/public/pgbench_accounts.sql
2020-04-27 23:43:37 INFO implode finished, stats: {'TABLE': 4}
2020-04-27 23:43:37 DEBUG main pgboom implode finished, result: {'TABLE': 4}
```

Concatenate SQL files created with `pgboom explode` into sigle SQL file:
```
$ pgboom cat '' /tmp/dl --File /tmp/dl.txt
2020-04-27 23:45:07 INFO implode finished, stats: {'SCHEMA': 2, 'EXTENSION': 1, 'FUNCTION': 45, 'AGGREGATE': None, 'SEQUENCE': 10, 'TABLE': 42, 'SEQUENCE_OWNED_BY': 1, 'PRIMARY_KEY': 5, 'CONSTRAINT': 19, 'INDEX': 75, 'VIEW': 9}
```

Example of `diff` functionality:

1. Prepare test database:
```
$ dropdb test
$ createdb test
$ pgbench test -i
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data...
100000 of 100000 tuples (100%) done (elapsed 0.08 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.
```
2. Explode test database to directory:
```
$ rm -rf /tmp/test
$ pgboom explode 'dbname=test' /tmp/test
2020-04-27 23:45:35 INFO explode finished, stats: {'SCHEMA': 1, 'EXTENSION': None, 'FUNCTION': None, 'AGGREGATE': None, 'SEQUENCE': None, 'TABLE': 4, 'SEQUENCE_OWNED_BY': None, 'PRIMARY_KEY': None, 'CONSTRAINT': None, 'INDEX': None, 'VIEW': None}
```
3. Modify the test database:
```
$ psql -X test -c 'create schema s0'
CREATE SCHEMA
$ psql -X test -c 'create view s0.v1 as select * from pgbench_branches'
CREATE VIEW
$ psql -X test -c 'alter table pgbench_branches add junk integer'
ALTER TABLE
$ psql -X test -c 'drop table pgbench_history'
DROP TABLE
```
4. Use `pgboom diff` to compare:
```
$ pgboom diff 'dbname=test' /tmp/test --File diff.txt
2020-04-27 23:46:07 INFO diff exploding database to /tmp/tmpemalxdg2
2020-04-27 23:46:07 INFO explode finished, stats: {'SCHEMA': 1, 'EXTENSION': None, 'FUNCTION': None, 'AGGREGATE': None, 'SEQUENCE': None, 'TABLE': 4, 'SEQUENCE_OWNED_BY': None, 'PRIMARY_KEY': None, 'CONSTRAINT': None, 'INDEX': None, 'VIEW': None}
2020-04-27 23:46:07 INFO diff comparing /tmp/tmpemalxdg2 to /tmp/test
```
5. View report of differences (context diff):
```
$ more diff.txt
```
```diff
diff -r -C3 -N /tmp/tmpkfanla1y/SCHEMA/s0/s0.sql /tmp/test/SCHEMA/s0/s0.sql
*** /tmp/tmpkfanla1y/SCHEMA/s0/s0.sql	2020-04-27 23:47:07.967715467 +0200
--- /tmp/test/SCHEMA/s0/s0.sql	1970-01-01 01:00:00.000000000 +0100
***************
*** 1 ****
- CREATE SCHEMA s0;
--- 0 ----
diff -r -C3 -N /tmp/tmpkfanla1y/TABLE/public/pgbench_branches.sql /tmp/test/TABLE/public/pgbench_branches.sql
*** /tmp/tmpkfanla1y/TABLE/public/pgbench_branches.sql	2020-04-27 23:47:07.979715569 +0200
--- /tmp/test/TABLE/public/pgbench_branches.sql	2020-04-27 23:45:35.966960723 +0200
***************
*** 1,6 ****
CREATE TABLE public.pgbench_branches (
    bid integer NOT NULL,
    bbalance integer,
!     filler character(88),
!     junk integer
) WITH (fillfactor=100);
--- 1,5 ----
CREATE TABLE public.pgbench_branches (
    bid integer NOT NULL,
    bbalance integer,
!     filler character(88)
) WITH (fillfactor=100);
diff -r -C3 -N /tmp/tmpkfanla1y/TABLE/public/pgbench_history.sql /tmp/test/TABLE/public/pgbench_history.sql
*** /tmp/tmpkfanla1y/TABLE/public/pgbench_history.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/TABLE/public/pgbench_history.sql	2020-04-27 23:45:35.966960723 +0200
***************
*** 0 ****
--- 1,8 ----
+ CREATE TABLE public.pgbench_history (
+     tid integer,
+     bid integer,
+     aid integer,
+     delta integer,
+     mtime timestamp without time zone,
+     filler character(22)
+ );
diff -r -C3 -N /tmp/tmpkfanla1y/PRIMARY_KEY/public/pgbench_accounts_pkey.sql /tmp/test/PRIMARY_KEY/public/pgbench_accounts_pkey.sql
*** /tmp/tmpkfanla1y/PRIMARY_KEY/public/pgbench_accounts_pkey.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/PRIMARY_KEY/public/pgbench_accounts_pkey.sql	2020-04-27 23:42:26.993598819 +0200
***************
*** 0 ****
--- 1 ----
+ ALTER TABLE public.pgbench_accounts ADD CONSTRAINT pgbench_accounts_pkey PRIMARY KEY (aid);
diff -r -C3 -N /tmp/tmpkfanla1y/PRIMARY_KEY/public/pgbench_branches_pkey.sql /tmp/test/PRIMARY_KEY/public/pgbench_branches_pkey.sql
*** /tmp/tmpkfanla1y/PRIMARY_KEY/public/pgbench_branches_pkey.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/PRIMARY_KEY/public/pgbench_branches_pkey.sql	2020-04-27 23:42:26.993598819 +0200
***************
*** 0 ****
--- 1 ----
+ ALTER TABLE public.pgbench_branches ADD CONSTRAINT pgbench_branches_pkey PRIMARY KEY (bid);
diff -r -C3 -N /tmp/tmpkfanla1y/PRIMARY_KEY/public/pgbench_tellers_pkey.sql /tmp/test/PRIMARY_KEY/public/pgbench_tellers_pkey.sql
*** /tmp/tmpkfanla1y/PRIMARY_KEY/public/pgbench_tellers_pkey.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/PRIMARY_KEY/public/pgbench_tellers_pkey.sql	2020-04-27 23:42:26.993598819 +0200
***************
*** 0 ****
--- 1 ----
+ ALTER TABLE public.pgbench_tellers ADD CONSTRAINT pgbench_tellers_pkey PRIMARY KEY (tid);
diff -r -C3 -N /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_accounts_bid_fkey.sql /tmp/test/CONSTRAINT/public/pgbench_accounts_bid_fkey.sql
*** /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_accounts_bid_fkey.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/CONSTRAINT/public/pgbench_accounts_bid_fkey.sql	2020-04-27 23:42:26.997598845 +0200
***************
*** 0 ****
--- 1 ----
+ ALTER TABLE public.pgbench_accounts ADD CONSTRAINT pgbench_accounts_bid_fkey FOREIGN KEY (bid) REFERENCES pgbench_branches(bid);
diff -r -C3 -N /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_history_aid_fkey.sql /tmp/test/CONSTRAINT/public/pgbench_history_aid_fkey.sql
*** /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_history_aid_fkey.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/CONSTRAINT/public/pgbench_history_aid_fkey.sql	2020-04-27 23:42:26.997598845 +0200
***************
*** 0 ****
--- 1 ----
+ ALTER TABLE public.pgbench_history ADD CONSTRAINT pgbench_history_aid_fkey FOREIGN KEY (aid) REFERENCES pgbench_accounts(aid);
diff -r -C3 -N /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_history_bid_fkey.sql /tmp/test/CONSTRAINT/public/pgbench_history_bid_fkey.sql
*** /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_history_bid_fkey.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/CONSTRAINT/public/pgbench_history_bid_fkey.sql	2020-04-27 23:42:26.997598845 +0200
***************
*** 0 ****
--- 1 ----
+ ALTER TABLE public.pgbench_history ADD CONSTRAINT pgbench_history_bid_fkey FOREIGN KEY (bid) REFERENCES pgbench_branches(bid);
diff -r -C3 -N /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_history_tid_fkey.sql /tmp/test/CONSTRAINT/public/pgbench_history_tid_fkey.sql
*** /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_history_tid_fkey.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/CONSTRAINT/public/pgbench_history_tid_fkey.sql	2020-04-27 23:42:26.997598845 +0200
***************
*** 0 ****
--- 1 ----
+ ALTER TABLE public.pgbench_history ADD CONSTRAINT pgbench_history_tid_fkey FOREIGN KEY (tid) REFERENCES pgbench_tellers(tid);
diff -r -C3 -N /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_tellers_bid_fkey.sql /tmp/test/CONSTRAINT/public/pgbench_tellers_bid_fkey.sql
*** /tmp/tmpkfanla1y/CONSTRAINT/public/pgbench_tellers_bid_fkey.sql	1970-01-01 01:00:00.000000000 +0100
--- /tmp/test/CONSTRAINT/public/pgbench_tellers_bid_fkey.sql	2020-04-27 23:42:26.997598845 +0200
***************
*** 0 ****
--- 1 ----
+ ALTER TABLE public.pgbench_tellers ADD CONSTRAINT pgbench_tellers_bid_fkey FOREIGN KEY (bid) REFERENCES pgbench_branches(bid);
diff -r -C3 -N /tmp/tmpkfanla1y/VIEW/s0/v1.sql /tmp/test/VIEW/s0/v1.sql
*** /tmp/tmpkfanla1y/VIEW/s0/v1.sql	2020-04-27 23:47:07.987715636 +0200
--- /tmp/test/VIEW/s0/v1.sql	1970-01-01 01:00:00.000000000 +0100
***************
*** 1,5 ****
- CREATE VIEW s0.v1 AS 
-  SELECT pgbench_branches.bid,
-     pgbench_branches.bbalance,
-     pgbench_branches.filler
-    FROM pgbench_branches;
--- 0 ----
```

Run a built-in test:
```
$ pgboom test 'dbname=test' /tmp/test
2020-04-27 23:48:44 INFO test entering test code - please ignore ERROR messages unless you see specific tests failing
2020-04-27 23:48:44 ERROR db_execute_ddl_file unexpected content in "/tmp/tmpipyu3_2v.sql"
2020-04-27 23:48:44 INFO explode finished, stats: {'SCHEMA': 2, 'EXTENSION': None, 'FUNCTION': None, 'AGGREGATE': None, 'SEQUENCE': 1, 'TABLE': 3, 'SEQUENCE_OWNED_BY': 1, 'PRIMARY_KEY': 1, 'CONSTRAINT': 2, 'INDEX': None, 'VIEW': 1}
2020-04-27 23:48:44 ERROR db_execute_ddl_file DUPLICATE_SCHEMA when executing /tmp/tempdb1588024124/SCHEMA/public/public.sql: schema "public" already exists
2020-04-27 23:48:44 INFO implode finished, stats: {'SCHEMA': 1, 'EXTENSION': None, 'FUNCTION': None, 'AGGREGATE': None, 'SEQUENCE': 1, 'TABLE': 3, 'SEQUENCE_OWNED_BY': 1, 'PRIMARY_KEY': 1, 'CONSTRAINT': 2, 'INDEX': None, 'VIEW': 1}
```


Known issues
------------

* PostgreSQL versions older than 11 are not supported.
* Not all object types are supported. This includes (among others):
  * Users and roles, (CREATE ROLE commands),
  * Privileges (GRANT commands),
  * Object ownership (ALTER ... OWNER),
  * User-defined types (CREATE TYPE),
  * User-defined operators (CREATE OPERATOR),
  * Row security policies (CREATE POLICY),
  * Triggers (CREATE TRIGGER),
  * Rules (CREATE RULE),
  * Tablespaces.
* The implode action does not care about dependencies and will most probably
  fail on a pre-populated database.
* WARNING! On implode, file content is only minimally validated.
  * It is your responsibility to use trusted directory as metadata source.
  * If there are multiple statements in a file, they will all be executed.
* The `diff` action produces only a context diff, nothing like a SQL patch; for
  this type of schema comparison tool, please check apgdiff project. 
* On `explode`, partition constraints and indexes are exported, even if they
  are inherited from master table. This may cause harmless ERRORs on implode.
* Schema / object names are not always properly quoted. This applies to VIEWs
  and maybe more.


Bugs
----

Please report bugs to 

* (preferred) https://github.com/filiprem/pg-tools/issues
* (last resort) directly to filip.rembialkowski@gmail.com.

