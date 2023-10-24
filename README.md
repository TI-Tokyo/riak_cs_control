# What is Riak CS Control?

Riak CS Control is a standalone user management application for Riak
CS.  It provides a user interface for filtering, disabling, creating
and managing users in a Riak CS Cluster.

It is implemented as a web app written in Elm. Assuming you installed it from a package,
start it with `riak-cs-control` and point your browser at <this-host-address>:8090.

## Configuring

The port on which the server running Riak CS Control web app will be
listening can be set via environment variable `RCSC_PORT`.
