/* 
 More: https://github.com/filiprem/pg-tools/

 Extract useful information from PostgreSQL system catalogs.

 Note: some of these queries might fail on some versions of PostgreSQL.
*/
SELECT CURRENT_TIMESTAMP;
SELECT version();
SELECT pg_is_in_recovery();
SELECT now() - min(stats_reset) AS probable_server_age FROM pg_stat_database;
SELECT pg_database_size(datname), CASE WHEN (blks_read+blks_hit)>0 THEN 100.0*blks_hit/(blks_read+blks_hit) END AS hit_ratio, * FROM pg_stat_database;
SELECT backend_type, state, count(*) FROM pg_stat_activity GROUP BY 1, 2 ORDER BY 1, 2;
SELECT age(now(), xact_start) xact_age, age(now(), backend_start) backend_age, * FROM pg_stat_activity ORDER BY xact_start, backend_start;
SELECT * FROM pg_stat_archiver;
SELECT * FROM pg_stat_bgwriter;
SELECT * FROM pg_stat_replication;
SELECT * FROM pg_stat_ssl WHERE ssl;
SELECT * FROM pg_stat_wal_receiver;
SELECT * FROM pg_roles ORDER BY oid LIMIT 1000;
SELECT * FROM pg_settings WHERE setting <> boot_val ORDER BY source, sourcefile, sourceline;
SELECT c.relkind, count(*), sum(c.relpages) relpages, sum(reltuples) reltuples, sum(c.relpages)*current_setting('block_size')::int relbytes FROM pg_class c GROUP BY 1 ORDER BY sum(c.relpages) DESC;
SELECT n.nspname, count(*), sum(c.relpages) relpages, sum(reltuples) reltuples, sum(c.relpages)*current_setting('block_size')::int relbytes FROM pg_class c, pg_namespace n WHERE n.oid=c.relnamespace GROUP BY 1 ORDER BY sum(c.relpages) DESC LIMIT 100;
SELECT * FROM pg_stat_all_tables ORDER BY coalesce(seq_scan+idx_scan,seq_scan,idx_scan,0) DESC, schemaname, relname LIMIT 1000;
SELECT sum(n_tup_ins) n_tup_ins, sum(n_tup_upd) n_tup_upd, sum(n_tup_del) n_tup_del, sum(n_tup_hot_upd) n_tup_hot_upd FROM pg_stat_all_tables;
SELECT * FROM pg_stat_all_indexes ORDER BY coalesce(idx_scan,0) DESC, schemaname, relname, indexrelname LIMIT 1000;
SELECT *, CASE WHEN idx_blks_read+idx_blks_hit>0 THEN 100.0*idx_blks_hit/(idx_blks_read+idx_blks_hit) END AS hit_ratio FROM pg_statio_all_indexes ORDER BY coalesce(idx_blks_read+idx_blks_hit,idx_blks_hit,idx_blks_read,0) DESC LIMIT 1000;
SELECT *, CASE WHEN (heap_blks_read+heap_blks_hit+idx_blks_read+idx_blks_hit+coalesce(toast_blks_read+toast_blks_hit+tidx_blks_read+tidx_blks_hit,0))>0 THEN 100.0*(heap_blks_hit+idx_blks_hit+coalesce(toast_blks_hit+tidx_blks_hit,0))/(heap_blks_read+heap_blks_hit+idx_blks_read+idx_blks_hit+coalesce(toast_blks_read+toast_blks_hit+tidx_blks_read+tidx_blks_hit,0)) END AS hit_ratio FROM pg_statio_all_tables ORDER BY coalesce(heap_blks_read+heap_blks_hit+idx_blks_read+idx_blks_hit, heap_blks_read+heap_blks_hit, 0) DESC LIMIT 1000;
SELECT schemaname, tablename, attname, null_frac, avg_width, n_distinct, substring(most_common_vals::text from 1 for 2000) as most_common_vals, most_common_freqs FROM pg_stats NATURAL JOIN (SELECT n.nspname AS schemaname, c.relname AS tablename FROM pg_namespace n, pg_class c WHERE c.relnamespace=n.oid AND c.relkind='r' AND c.relpages>1 ORDER BY c.relpages DESC LIMIT 20) x ORDER BY schemaname, tablename, attname;
SELECT * FROM pg_stat_user_functions ORDER BY total_time DESC LIMIT 1000;
SELECT calls, round((total_plan_time+total_exec_time)::numeric,0) AS total_time, round((mean_plan_time+mean_exec_time)::numeric,2) AS mean_time, round(rows::numeric/calls,0) as avg_rows, substring(query from 1 for 2000) as query, shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written, local_blks_hit, local_blks_read, local_blks_dirtied, local_blks_written, temp_blks_read, temp_blks_written, blk_read_time, blk_write_time, userid, dbid, queryid FROM pg_stat_statements ORDER BY total_time DESC LIMIT 1000;
SELECT locktype, mode, count(*) FROM pg_locks GROUP BY 1, 2 ORDER BY 1, 2;
SELECT psa.xact_start, age(now(), psa.xact_start) AS xact_age, l.pid, l.locktype, l.mode, l.granted::text, l.relation::regclass, psa.usename, regexp_replace(psa.query, E'(\\r|\\n|\\t)+', ' ', 'g') AS query FROM pg_stat_activity psa JOIN pg_locks l on l.pid = psa.pid LEFT JOIN pg_class c on c.oid = l.relation ORDER BY 1;
SELECT * FROM pg_extension;
SELECT pg_current_wal_lsn(), * FROM pg_walfile_name_offset(pg_current_wal_lsn());
SELECT * FROM timescaledb_information.hypertables;
SELECT * FROM timescaledb_information.continuous_aggregates;
