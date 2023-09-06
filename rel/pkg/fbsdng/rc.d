#!/bin/sh

# $FreeBSD$
#
# PROVIDE: riak_cs_control
# REQUIRE: LOGIN
# KEYWORD: shutdown

. /etc/rc.subr

name=riak_cs_control
command=/usr/local/lib/riak-cs-control/%ERTS_PATH%/bin/beam.smp
rcvar=riak_cs_control_enable
start_cmd="/usr/local/lib/riak-cs-control/bin/riak-cs-control start"
stop_cmd="/usr/local/lib/riak-cs-control/bin/riak-cs-control stop"
pidfile="/run/riak-cs-control/riak-cs-control.pid"

riak_cs_control_user=riak_cs_control
riak_cs_control_env_file="/usr/local/etc/riak-cs-control/config"

load_rc_config $name
run_rc_command "$1"
