pgboom
======

The `pgboom` program manipulates Postgres metadata.

It can extract (**`explode`**) object metadata (ie., database schema) from PostgreSQL
database to directory of flat SQL files, and vice versa (**`implode`**).

Each db object goes into separate file, `DIR/OBJECT-CLASS/SCHEMA-NAME/OBJECT-NAME.sql`.

Example directory representing a pgbench database initialized with `pgbench -i --foreign-keys`:
```
/tmp/test/TABLE/public/pgbench_tellers.sql
/tmp/test/TABLE/public/pgbench_history.sql
/tmp/test/TABLE/public/pgbench_branches.sql
/tmp/test/TABLE/public/pgbench_accounts.sql
/tmp/test/CONSTRAINT/public/pgbench_accounts_bid_fkey.sql
/tmp/test/CONSTRAINT/public/pgbench_accounts_pkey.sql
/tmp/test/CONSTRAINT/public/pgbench_history_bid_fkey.sql
/tmp/test/CONSTRAINT/public/pgbench_history_aid_fkey.sql
/tmp/test/CONSTRAINT/public/pgbench_tellers_pkey.sql
/tmp/test/CONSTRAINT/public/pgbench_branches_pkey.sql
/tmp/test/CONSTRAINT/public/pgbench_tellers_bid_fkey.sql
/tmp/test/CONSTRAINT/public/pgbench_history_tid_fkey.sql
```

The `pgboom` program can also compare (**`diff`**) existing database to directory, producting a report of differences.

It can also concatenate (**`cat`**) directory contents into single SQL file.


Synopsis
--------

```
usage: pgboom [-h]
              [--Class {SCHEMA,FUNCTION,AGGREGATE,SEQUENCE,TABLE,CONSTRAINT,INDEX,VIEW}]
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
  --Class {SCHEMA,FUNCTION,AGGREGATE,SEQUENCE,TABLE,CONSTRAINT,INDEX,VIEW}, -C {SCHEMA,FUNCTION,AGGREGATE,SEQUENCE,TABLE,CONSTRAINT,INDEX,VIEW}
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
2020-04-19 16:30:42 INFO explode_class processing SCHEMA definitions
2020-04-19 16:30:42 INFO explode_class processing FUNCTION definitions
2020-04-19 16:30:42 INFO explode_class processing AGGREGATE definitions
2020-04-19 16:30:42 INFO explode_class processing SEQUENCE definitions
2020-04-19 16:30:42 INFO explode_class processing TABLE definitions
2020-04-19 16:30:42 INFO explode_class processing CONSTRAINT definitions
2020-04-19 16:30:42 INFO explode_class processing INDEX definitions
2020-04-19 16:30:42 INFO explode_class processing VIEW definitions
2020-04-19 16:30:42 INFO explode finished, stats: {'SCHEMA': 1, 'FUNCTION': None, 'AGGREGATE': None, 'SEQUENCE': None, 'TABLE': 4, 'CONSTRAINT': 8, 'INDEX': None, 'VIEW': None}
```

Import directory into database, filtering by schema and object name:
```
$ pgboom implode 'dbname=test' /tmp/test --Class TABLE --Schema public --Object '^pgbench' --dry-run --debug
2020-04-19 16:28:07 DEBUG main pgboom implode starting
2020-04-19 16:28:07 INFO main running in simulation mode
2020-04-19 16:28:07 DEBUG main testing database connection
2020-04-19 16:28:07 DEBUG main connection OK: user=filip, db=test, version=PostgreSQL 12.2 (Ubuntu 12.2-2.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
2020-04-19 16:28:07 INFO implode_class processing TABLE definitions
2020-04-19 16:28:07 DEBUG implode_class processing /tmp/test/TABLE/public/pgbench_tellers.sql
2020-04-19 16:28:07 DEBUG implode_class processing /tmp/test/TABLE/public/pgbench_history.sql
2020-04-19 16:28:07 DEBUG implode_class processing /tmp/test/TABLE/public/pgbench_branches.sql
2020-04-19 16:28:07 DEBUG implode_class processing /tmp/test/TABLE/public/pgbench_accounts.sql
2020-04-19 16:28:07 INFO implode finished, stats: {'TABLE': None}
2020-04-19 16:28:07 DEBUG main pgboom implode finished
```

Concatenate SQL files created with `pgboom explode` into sigle SQL file:
```
$ pgboom cat '' /tmp/dl --File /tmp/dl.txt
2020-04-19 16:14:44 INFO implode_class processing SCHEMA definitions
2020-04-19 16:14:44 INFO implode_class processing FUNCTION definitions
2020-04-19 16:14:44 INFO implode_class directory /tmp/dl/AGGREGATE does not exist
2020-04-19 16:14:44 INFO implode_class processing SEQUENCE definitions
2020-04-19 16:14:44 INFO implode_class processing TABLE definitions
2020-04-19 16:14:44 INFO implode_class processing CONSTRAINT definitions
2020-04-19 16:14:44 INFO implode_class processing INDEX definitions
2020-04-19 16:14:44 INFO implode_class processing VIEW definitions
2020-04-19 16:14:44 INFO implode finished, stats: {'SCHEMA': 2, 'FUNCTION': 75, 'AGGREGATE': None, 'SEQUENCE': 10, 'TABLE': 42, 'CONSTRAINT': 5, 'INDEX': 94, 'VIEW': 9}
```

Example of `diff` functionality:

1. Prepare test database:
```bash
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
    2020-04-23 16:35:58 INFO explode finished, stats: {'SCHEMA': 1, 'FUNCTION': None, 'AGGREGATE': None, 'SEQUENCE': None, 'TABLE': 4, 'CONSTRAINT': 3, 'INDEX': None, 'VIEW': None}
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
    2020-04-23 16:35:58 INFO diff exploding database to /tmp/test.drk6cm67
    2020-04-23 16:35:58 INFO explode finished, stats: {'SCHEMA': 2, 'FUNCTION': None, 'AGGREGATE': None, 'SEQUENCE': None, 'TABLE': 3, 'CONSTRAINT': 3, 'INDEX': None, 'VIEW': 1}
    2020-04-23 16:35:58 INFO diff comparing /tmp/test.drk6cm67 to /tmp/test
```
5. View report of differences (context diff):
```diff
    $ more diff.txt
    diff -r -C3 -N /tmp/test.drk6cm67/SCHEMA/s0/s0.sql /tmp/test/SCHEMA/s0/s0.sql
    *** /tmp/test.drk6cm67/SCHEMA/s0/s0.sql	2020-04-23 16:35:58.765429239 +0200
    --- /tmp/test/SCHEMA/s0/s0.sql	1970-01-01 01:00:00.000000000 +0100
    ***************
    *** 1 ****
    - CREATE SCHEMA s0;
    --- 0 ----
    diff -r -C3 -N /tmp/test.drk6cm67/TABLE/public/pgbench_branches.sql /tmp/test/TABLE/public/pgbench_branches.sql
    *** /tmp/test.drk6cm67/TABLE/public/pgbench_branches.sql	2020-04-23 16:35:58.813429444 +0200
    --- /tmp/test/TABLE/public/pgbench_branches.sql	2020-04-23 16:35:58.605428552 +0200
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
    diff -r -C3 -N /tmp/test.drk6cm67/TABLE/public/pgbench_history.sql /tmp/test/TABLE/public/pgbench_history.sql
    *** /tmp/test.drk6cm67/TABLE/public/pgbench_history.sql	1970-01-01 01:00:00.000000000 +0100
    --- /tmp/test/TABLE/public/pgbench_history.sql	2020-04-23 16:35:58.605428552 +0200
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
    diff -r -C3 -N /tmp/test.drk6cm67/VIEW/s0/v1.sql /tmp/test/VIEW/s0/v1.sql
    *** /tmp/test.drk6cm67/VIEW/s0/v1.sql	2020-04-23 16:35:58.817429462 +0200
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
2020-04-19 16:31:32 INFO main entering test code - please ignore ERROR messages unless you see specific tests failing
2020-04-19 16:31:32 ERROR db_execute_ddl_file unexpected content in "/tmp/tmpd9d_wvzs.sql"
```


Known issues
------------

* Not all object types are supported.
* PostgreSQL versions older than 11 are not supported.
* The implode action does not care about dependencies and will most probably
  fail on a pre-populated database.
* WARNING! On implode, file content is not validated. It is your responsibility
  to use trusted data source.
* WARNING! On implode, there is almost no SQL validation and if there are
  multiple statements in a file, they will all be executed.
* Many object properties are not reflected on explode. For example, `LEAKPROOF`
  attribute for functions is not exploded.
* Schema / object names are not always properly quoted. This applies to VIEWs
  and maybe more.
* The `diff` action produces only a context diff, nothing like a SQL patch; for
  this type of schema comparison tool, please check apgdiff project. 


Bugs
----

Please report bugs to 

* (preferred) https://github.com/filiprem/pg-tools/issues
* (last resort) directly to filip.rembialkowski@gmail.com.

