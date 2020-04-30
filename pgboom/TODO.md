pgboom TODO list
================

* Ensure proper quoting of all identifiers (+remove readme entry).

* support ACLs (GRANT).

* optionally, do something (overwrite? diff?) with pre-existing objects on implode

* implement "SQL diff" (producing ALTER to patch db).
  * Note: this is hard.

* handle object dependencies on explode / implode / cat.
  * Note: This is hard. Full topological sort would be required to resolve all
    dependencies properly. As of now, I used separate object classes to
    guarantee sensible implode order in most cases.

