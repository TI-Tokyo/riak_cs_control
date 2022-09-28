#!/bin/sh

# $FreeBSD$
#
# PROVIDE: riak_cs_control
# REQUIRE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr

name=riak_cs_control
command=/usr/local/lib/riak_cs_control/%ERTS_PATH%/bin/beam.smp
rcvar=riak_cs_control_enable
start_cmd="/usr/local/bin/riak_cs_control start"
stop_cmd="/usr/local/bin/riak_cs_control stop"
pidfile="/var/run/riak_cs_control/riak_cs_control.pid"

load_rc_config $name
run_rc_command "$1"
