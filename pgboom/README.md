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
                        
                        diff: Compares object definitions between directory and database.
                            The directory is suposed to be pre-populated with `pgboom explode`.
                        
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
  --File FILE, -F FILE  Output file for the "cat" action
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

* The implode action does not care about dependencies and will most probably fail on a pre-populated database.

* WARNING! On implode, file content is not validated. It is your responsibility to use trusted data source.

* WARNING! On implode, there is almost no SQL validation and if there are multiple statements in a file, they will all be executed.

* Many object properties are not reflected on explode. For example, `LEAKPROOF` attribute for functions is not exploded.

* Schema / object names are not always properly quoted. This applies to VIEWs and maybe more.


Bugs
----

Please report bugs to 

* (preferred) https://github.com/filiprem/pg-tools/issues
* (last resort) directly to filip.rembialkowski@gmail.com.

