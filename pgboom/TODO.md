pgboom TODO list
================

* Support partitioned tables and their partitions

* Work around CONSTRAINT-to-CONSTRAINT dependencies (separate handling of PKEYs?)

* support ACLs

* implement "SQL diff" (producing ALTER to patch db). Note: this is hard.

* switch to Python "logging" instead of custom "debug" function.

* handle object dependencies on explode / implode / cat.

* optionally, do something (overwrite? diff?) with pre-existing objects on implode

