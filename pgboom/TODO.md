pgboom TODO list
================

* Support partitioned tables and their partitions

* support ACLs

* implement "SQL diff" (producing ALTER to patch db). Note: this is hard.

* switch to Python "logging" instead of custom "debug" function.

* handle object dependencies on explode / implode / cat.
  * Note: Full topological sort would be required to resolve all deps properly.

* optionally, do something (overwrite? diff?) with pre-existing objects on implode

