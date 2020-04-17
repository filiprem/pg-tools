pgboom
======

Utility to extract object metadata (ie., database schema) from PostgreSQL
database to directory of flat SQL files, and vice versa.

Each db object goes into separate file, `DIR/OBJECT-CLASS/SCHEMA-NAME/OBJECT-NAME.sql`


Synopsis
--------

    usage: pgboom [-h]
                [--Class {SCHEMA,FUNCTION,AGGREGATE,SEQUENCE,TABLE,CONSTRAINT,INDEX,VIEW}]
                [--Schema SCHEMA] [--Object OBJECT] [--test] [--debug]
                [--dry-run]
                {explode,implode,test} DSN DIR

    Utility to extract object metadata (ie., database schema) from PostgreSQL
    database to directory structure, and vice versa. Each db object goes into
    separate file: `DIR/OBJECT-CLASS/SCHEMA-NAME/OBJECT-NAME.sql`.

    positional arguments:
    {explode,implode,test}
                            Action to perform
    DSN                   PostgreSQL data source in 'key=value' format
    DIR                   Destination/source directory

    optional arguments:
    -h, --help            show this help message and exit
    --Class {SCHEMA,FUNCTION,AGGREGATE,SEQUENCE,TABLE,CONSTRAINT,INDEX,VIEW}, -C {SCHEMA,FUNCTION,AGGREGATE,SEQUENCE,TABLE,CONSTRAINT,INDEX,VIEW}
                            Type of objects to extract/load
    --Schema SCHEMA, -S SCHEMA
                            Database schema name filter
    --Object OBJECT, -O OBJECT
                            Database object name filter
    --test                Perform built-in test
    --debug, --verbose, -v
                            Set verbose debugging on
    --dry-run             Simulation mode (avoid any side effects)


Examples
-------

Explode all objects from database into directory:
```
$ pgboom explode 'host=localhost port=5432 dbname=test' /tmp/test --debug
2020-04-14 20:50:17 INFO explode_class exploding VIEW definitions
2020-04-14 20:50:17 INFO explode_class exploding FUNCTION definitions
2020-04-14 20:50:17 INFO explode_class exploding TABLE definitions
2020-04-14 20:50:17 INFO explode_class exploding INDEX definitions
2020-04-14 20:50:17 INFO explode_class exploding CONSTRAINT definitions
2020-04-14 20:50:17 INFO explode Finished exploding database into /tmp/test. Stats: {'VIEW': None, 'FUNCTION': None, 'TABLE': 4, 'INDEX': None, 'CONSTRAINT': 8}
```

Implode directory into database, filtering by schema and object name:
```
pgboom implode 'host=localhost port=5432 dbname=dl' /tmp/dl --Class FUNCTION --Schema dl --Object '^getrecursivecolumns\b'
2020-04-15 18:25:22 INFO implode_class Going to execute /tmp/dl/FUNCTION/dl/getrecursivecolumns(varchar,text,int4,bool).sql
2020-04-15 18:25:22 INFO implode Finished imploding /tmp/dl into database. Stats: {'FUNCTION': 1}
```

Run a built-in test:
```
pgboom test 'dbname=test' /tmp/test
2020-04-17 18:12:47 INFO main Entering test code. Please ignore ERROR messages, unless you see specific tests failing.
2020-04-17 18:12:47 ERROR db_execute_ddl_file Unexpected content in "/tmp/tmplwv50dam.sql"
```


Known issues
------------

* Not all object types are supported.

* PostgreSQL versions older than 11 are not supported.

* WARNING! On implode, file content is not validated. It is your responsibility to use trusted data source.

* WARNING! On implode, there is almost no SQL validation and if there are multiple statements in a file, they will all be executed.

* The whole implode action does not care about dependencies and will most probably fail on a pre-populated database.

* Not all object properties are reflected on explode. For example, `LEAKPROOF` attribute for functions is not exploded.

* Schema / object names are not always properly quoted. This applies to VIEWs and maybe more.


Bugs
----

Please report bugs to 

* (preferred) https://github.com/filiprem/pg-tools/issues
* (last resort) directly to filip.rembialkowski@gmail.com.

