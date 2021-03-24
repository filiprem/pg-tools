#!/usr/bin/env python3
"""
(filip@[local]:5432) filip=# SELECT *    FROM pg_stat_activity
              WHERE pid = 93950
              AND client_port = 60510
;
-[ RECORD 1 ]----+------------------------------
datid            | 211174
datname          | filip
pid              | 93950
leader_pid       | NULL
usesysid         | 16386
usename          | filip
application_name | psql
client_addr      | 127.0.0.1
client_hostname  | NULL
client_port      | 60510
backend_start    | 2021-03-23 17:07:34.396749+01
xact_start       | 2021-03-23 17:07:37.090912+01
query_start      | 2021-03-23 17:07:37.091214+01
state_change     | 2021-03-23 17:07:37.091216+01
wait_event_type  | Lock
wait_event       | relation
state            | active
backend_xid      | 755265
backend_xmin     | 755265
query            | DROP TABLE pgbench_branches;
backend_type     | client backend

# [sconn(fd=6, family=<AddressFamily.AF_INET6: 10>, type=<SocketKind.SOCK_STREAM: 1>, laddr=addr(ip='::', port=111), raddr=(), status='LISTEN', pid=768),
# ...,
# sconn(fd=10, family=<AddressFamily.AF_INET: 2>, type=<SocketKind.SOCK_STREAM: 1>, laddr=addr(ip='127.0.0.1', port=5432), raddr=addr(ip='127.0.0.1', port=60510), status='CLOSE_WAIT', pid=93950)]

"""

import psutil

def pg_cancel_backend(pid, rport):
    if pid is None or rport is None:
        return
    print(f"""
        SELECT pg_cancel_backend(pid) FROM pg_stat_activity
        WHERE pid = {pid} AND client_port = {rport}
        AND state_change < now() - '45 seconds'::interval;
    """)

for proc in psutil.process_iter(['pid', 'name', 'status', 'username', 'cmdline']):
    if proc.info['username'] == 'postgres':
        print(f'PID {proc.pid} status {proc.status()} cmd {proc.info["cmdline"][0]}')
        for conn in proc.connections():
            if conn.status == 'CLOSE_WAIT':
                pg_cancel_backend(proc.pid, conn.raddr.port)
