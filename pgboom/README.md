pgboom
======

Utility to extract object metadata (ie., database schema) from PostgreSQL database into directory of flat files.

Each db object goes into separate file, `DIR/OBJECT-CLASS/SCHEMA-NAME/OBJECT-NAME.sql`

Synopsis
--------

    usage: pgboom [-h] [--Class {VIEW,FUNCTION,TABLE,INDEX,CONSTRAINT}]
                [--Schema SCHEMA] [--Object OBJECT] [--test] [--debug]
                [--dry-run]
                ACTION DSN DIR

    positional arguments:
    ACTION                Action (explode/implode)
    DSN                   PostgreSQL data source in 'key=value' format
    DIR                   Destination/source directory

    optional arguments:
    -h, --help            show this help message and exit
    --Class {VIEW,FUNCTION,TABLE,INDEX,CONSTRAINT}, -C {VIEW,FUNCTION,TABLE,INDEX,CONSTRAINT}
                            Type of objects to extract/load
    --Schema SCHEMA, -S SCHEMA
                            Database schema name filter
    --Object OBJECT, -O OBJECT
                            Database object name filter
    --test                Perform built-in test
    --debug, --verbose, -v
                            Set verbose debugging on
    --dry-run             Simulation mode (avoid any side effects)


Example
-------

```
$ pgboom explode 'host=localhost port=5432 dbname=test' /tmp/test --debug
2020-04-14 20:50:17 DEBUG main Testing database connection for metadata import
2020-04-14 20:50:17 DEBUG main Connection OK, user=filip, db=test, version=PostgreSQL 12.2 (Ubuntu 12.2-2.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
2020-04-14 20:50:17 INFO import_class importing VIEW definitions
2020-04-14 20:50:17 INFO import_class importing FUNCTION definitions
2020-04-14 20:50:17 INFO import_class importing TABLE definitions
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/TABLE/public/pgbench_accounts.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/TABLE/public/pgbench_branches.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/TABLE/public/pgbench_history.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/TABLE/public/pgbench_tellers.sql
2020-04-14 20:50:17 INFO import_class importing INDEX definitions
2020-04-14 20:50:17 INFO import_class importing CONSTRAINT definitions
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/CONSTRAINT/public/pgbench_accounts_bid_fkey.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/CONSTRAINT/public/pgbench_accounts_pkey.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/CONSTRAINT/public/pgbench_branches_pkey.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/CONSTRAINT/public/pgbench_history_aid_fkey.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/CONSTRAINT/public/pgbench_history_bid_fkey.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/CONSTRAINT/public/pgbench_history_tid_fkey.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/CONSTRAINT/public/pgbench_tellers_bid_fkey.sql
2020-04-14 20:50:17 DEBUG import_class going to save /tmp/test/CONSTRAINT/public/pgbench_tellers_pkey.sql
2020-04-14 20:50:17 INFO explode Finished importing objects to /tmp/test. Stats: {'VIEW': 0, 'FUNCTION': 0, 'TABLE': 4, 'INDEX': 0, 'CONSTRAINT': 8}
```

Known issues
------------

* The "implode" action is not (yet) supported. Obviously, it's a lot more complex than "explode".
* Not all object properties are reflected on export. For example, `LEAKPROOF` attribute for functions.
* Schema / object names are not always properly quoted. This applies to VIEWs and maybe more.


Bugs
----

Please report bugs to 

* (preferred) https://github.com/filiprem/pg-tools/issues
* (last resort) directly to filip.rembialkowski@gmail.com.

