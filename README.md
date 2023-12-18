# What is Riak CS Control?

Riak CS Control is a standalone user management application for Riak
CS.  It provides a web-based user interface for:

* filtering, disabling, creating and managing users in a Riak CS
  Cluster;
* policies, roles and SAML providers;
* user disk stats.

It is implemented as a web app written in Elm. Assuming you installed
it from a package, start it with `riak-cs-control` and point your
browser at <this-host-address>:8090.

## Configuring

The port on which the server running Riak CS Control web app will be
listening can be set via environment variable `RCSC_PORT`.

Note that unless you only intend to run and access Riak CS Control on
the same node that runs your Riak CS node, you will need to change the
value of `listener` in riak-cs.conf to 0.0.0.0:8080 (or similar).
