#!/bin/bash

tag=$(hostname).$(date +%Y%m%d%H%M%S)
log=/tmp/postgres-checkdb.$tag.log
logerr=/tmp/postgres-checkdb-error.$tag.log
exec > >(tee $log) 2> >(tee $logerr >&2)

echo "STARTED (log: $log, errors: $logerr)"

export LC_ALL=C

# execute as postgres user
[[ "$(id -nu)" =~ (postgres|pgdba|enterprisedb|ppas) ]] || { echo "STOP (please run as postgres user)" >&2; exit 1; }

# find binaries
mybin=$(ps ax | perl -lne 'print $1 if m{\s(/\S+/)(postgres|postmaster) -D}')
for tool in postgres pg_ctl pg_controldata psql; do
	found=$(find $mybin /bin/ /sbin/ /usr/bin/ /usr/sbin/ /usr/lib/ /opt/ -name $tool -type f -perm -111 2>/dev/null | head -n1)
	eval $tool=${found:-$tool}
done

[ "$psql" ] || { echo "STOP (could not locate psql binary)" >&2; exit 2; }

$psql -XqAtc 'select version()' || { echo "STOP (could not connect to default database)" >&2; exit 3; }

clusters=$(
ls -d \
	"$PGDATA" \
	"$HOME/data" \
	"$($psql -XqAtc 'show data_directory')" \
	/var/lib/pgsql/*/data \
	/var/lib/pgsql/data \
	/var/lib/postgresql/*/* \
	2>/dev/null | sort | uniq
)

# find data directory of a running cluster
for data in $clusters
do
  [ -d "$data" -a -f "$data/PG_VERSION" -a -f "$data/postmaster.pid" ] && break
done
[ -d $data -a -f $data/PG_VERSION ] || { echo "STOP (could not find a running cluster)" >&2; exit 4; }

SERVER_PID=$(head -n 1 "$data/postmaster.pid")

for command in \
  "date" \
  "uptime" \
  "uname -a" \
  "cat /etc/os-release" \
  "env" \
  "lscpu" \
  "free -h" \
  "df -hT" \
  "iostat -cdtxyz 5 1" \
  "grep ^VmPeak /proc/$SERVER_PID/status" \
  "grep ^Hugepagesize /proc/meminfo" \
  "ps xf" \
  "$postgres --version" \
  "ls -la $data" \
  "$pg_ctl status -D $data" \
  "$pg_controldata $data" \
  "du -sLh $data" \
  "du -sLh $data/pg_wal" \
  "du -sLh $data/pg_xlog" \
  "$psql -l"
do
  echo "Running command: $command"
  echo "======== Command output for [ $command ] ==========="
  eval $command 2>&1
  echo "======== Command output finished =========="
done

# Cluster-wide queries.

for sql in \
  "SELECT version()" \
  "SELECT pg_database_size(datname), CASE WHEN (blks_read+blks_hit)>0 THEN 100.0*blks_hit/(blks_read+blks_hit) END AS hit_ratio, * FROM pg_stat_database" \
  "SELECT age(now(), xact_start) xact_age, age(now(), backend_start) backend_age, * FROM pg_stat_activity ORDER BY xact_start, backend_start" \
  "SELECT * FROM pg_stat_archiver" \
  "SELECT * FROM pg_stat_bgwriter" \
  "SELECT * FROM pg_stat_replication" \
  "SELECT * FROM pg_stat_ssl WHERE ssl" \
  "SELECT * FROM pg_stat_wal_receiver" \
  "SELECT * FROM pg_authid ORDER BY oid LIMIT 1000" \
  "SELECT * FROM pg_settings WHERE setting <> boot_val ORDER BY source, sourcefile, sourceline" \
  "SELECT pg_current_wal_lsn(), * FROM pg_walfile_name_offset(pg_current_wal_lsn())"
do
  echo "Running SQL: $sql"
  {
    echo "======== SQL output for [ $sql ] ========"
    $psql -Xqc "$sql" 2>&1
    echo "======== SQL output finished ========"
  }
done

# Per-database queries.

for db in $( $psql -XqAtc "SELECT datname FROM pg_database
  WHERE datname NOT IN ('template0','template1','postgres')
  ORDER BY datname" )
do
  for sql in \
    "SELECT c.relkind, count(*), sum(c.relpages) relpages, sum(reltuples) reltuples, sum(c.relpages)*current_setting('block_size')::int relbytes FROM pg_class c GROUP BY 1 ORDER BY sum(c.relpages) DESC" \
    "SELECT n.nspname, count(*), sum(c.relpages) relpages, sum(reltuples) reltuples, sum(c.relpages)*current_setting('block_size')::int relbytes FROM pg_class c, pg_namespace n WHERE n.oid=c.relnamespace GROUP BY 1 ORDER BY sum(c.relpages) DESC LIMIT 100" \
    "SELECT * FROM pg_stat_all_tables ORDER BY coalesce(seq_scan+idx_scan,seq_scan,idx_scan,0) DESC, schemaname, relname LIMIT 1000" \
	"SELECT sum(n_tup_ins) n_tup_ins, sum(n_tup_upd) n_tup_upd, sum(n_tup_del) n_tup_del, sum(n_tup_hot_upd) n_tup_hot_upd FROM pg_stat_all_tables" \
    "SELECT * FROM pg_stat_all_indexes ORDER BY coalesce(idx_scan,0) DESC, schemaname, relname, indexrelname LIMIT 1000" \
    "SELECT *, CASE WHEN idx_blks_read+idx_blks_hit>0 THEN 100.0*idx_blks_hit/(idx_blks_read+idx_blks_hit) END AS hit_ratio FROM pg_statio_all_indexes ORDER BY coalesce(idx_blks_read+idx_blks_hit,idx_blks_hit,idx_blks_read,0) DESC LIMIT 1000" \
	"SELECT *, CASE WHEN (heap_blks_read+heap_blks_hit+idx_blks_read+idx_blks_hit+coalesce(toast_blks_read+toast_blks_hit+tidx_blks_read+tidx_blks_hit,0))>0 THEN 100.0*(heap_blks_hit+idx_blks_hit+coalesce(toast_blks_hit+tidx_blks_hit,0))/(heap_blks_read+heap_blks_hit+idx_blks_read+idx_blks_hit+coalesce(toast_blks_read+toast_blks_hit+tidx_blks_read+tidx_blks_hit,0)) END AS hit_ratio FROM pg_statio_all_tables ORDER BY coalesce(heap_blks_read+heap_blks_hit+idx_blks_read+idx_blks_hit, heap_blks_read+heap_blks_hit, 0) DESC LIMIT 1000" \
	"SELECT schemaname, tablename, attname, null_frac, avg_width, n_distinct, substring(most_common_vals::text from 1 for 2000) as most_common_vals, most_common_freqs FROM pg_stats NATURAL JOIN (SELECT n.nspname AS schemaname, c.relname AS tablename FROM pg_namespace n, pg_class c WHERE c.relnamespace=n.oid AND c.relkind='r' AND c.relpages>1 ORDER BY c.relpages DESC LIMIT 20) x ORDER BY schemaname, tablename, attname" \
    "SELECT * FROM pg_stat_user_functions ORDER BY total_time DESC LIMIT 1000" \
	"SELECT psa.xact_start, age(now(), psa.xact_start) AS xact_age, l.pid, l.locktype, l.mode, l.granted::text, l.relation::regclass, psa.usename, regexp_replace(psa.query, E'(\\r|\\n|\\t)+', ' ', 'g') AS query FROM pg_stat_activity psa JOIN pg_locks l on l.pid = psa.pid LEFT JOIN pg_class c on c.oid = l.relation ORDER BY 1"
  do
    echo "Running SQL in $db: $sql"
	{
	  echo "======== DB: $db ========"
	  echo "======== SQL output for [ $sql ] ========"
      $psql -Xqc "$sql" $db 2>&1
      echo "======== SQL output finished ========"
	}
  done
done

echo "FINISHED (log: $log, errors: $logerr)"
