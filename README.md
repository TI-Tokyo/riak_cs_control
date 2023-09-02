# What is Riak CS Control?

Riak CS Control is a standalone user management application for Riak
CS.  It provides a user interface for filtering, disabling, creating
and managing users in a Riak CS Cluster.

## Configuring

Riak CS Control will consult its configuration from the following
environment variables (with defaults where value is optional):

```
CS_HOST          # 127.0.0.1
CS_PORT          # 8080
CS_PROTO         # http
CS_CONTROL_PORT  # 8090
CS_ADMIN_KEY     # admin-key
CS_ADMIN_SECRET  # admin-secret
LOG_DIR          # ./log
LOGGER_LEVEL     # info
```

When installed from a package and started via `systemctl` or `service`
these variables can be set in
/etc/systemd/system/riak-cs-control.service.d (on all Linuxes with
systemd) and /usr/local/etc/riak-cs-control/config (on FreeBSD).

## Running

Start Riak CS Control as you would Riak or Riak CS, e.g.:
`/path/to/riak-cs-control start`. When installed from a package, it
can be started as a service (`systemctl` on Linux distros that adopted
systemd, or `service` on Freebsd or Alpine Linux).
