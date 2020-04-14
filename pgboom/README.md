pgboom
======

Utility to extract metadata from PostgreSQL into directory of flat files.

Synopsis
--------

    usage: pgboom [-h] [--Class {VIEW,FUNCTION,TABLE,INDEX,CONSTRAINT}]
                [--Schema SCHEMA] [--Object OBJECT] [--test] [--debug]
                [--dry-run]
                ACTION DSN DIR

    Utility to extract object metadata (ie., database schema) from PostgreSQL
    database to directory structure. Each db object goes into separate file,
    DIR/OBJECT-CLASS/SCHEMA-NAME/OBJECT-NAME.sql

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
