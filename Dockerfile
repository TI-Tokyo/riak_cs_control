FROM erlang:22 AS compile-image

ARG cs_host=127.0.0.1 \
    cs_port=8080

EXPOSE $cs_port

WORKDIR /usr/src/riak_cs_control
COPY . /usr/src/riak_cs_control

RUN ./rebar3 as docker release

FROM debian:buster AS runtime-image

RUN apt-get update && apt-get -y install libssl1.1

COPY --from=compile-image /usr/src/riak_cs/_build/docker/rel/riak_cscontrol /opt/riak_cs_control

COPY --from=compile-image /usr/src/riak_cs/rel/docker/tini /tini
RUN chmod +x /tini

ENTRYPOINT ["/tini", "--"]
CMD ["/opt/riak_cs_control/bin/riak_cs_control", "foreground"]
