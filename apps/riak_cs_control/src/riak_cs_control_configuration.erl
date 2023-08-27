%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2012 Basho Technologies, Inc.  All Rights Reserved.
%%
%% -------------------------------------------------------------------

%% @author Christopher Meiklejohn <cmeiklejohn@basho.com>
%% @copyright 2012 Basho Technologies, Inc.

%% @doc Helpers for configuration.

-module(riak_cs_control_configuration).
-author('Christopher Meiklejohn <cmeiklejohn@basho.com>').

-export([get/1,
         get/2]).

%% @doc Return one configuration value from the environment.
-spec get(atom()) -> term().
get(Attribute) ->
    {ok, Value} = application:get_env(riak_cs_control, Attribute),
    Value.

%% @doc Return one configuration value from the environment with default.
-spec get(atom(), term()) -> term().
get(Attribute, Default) ->
    case application:get_env(riak_cs_control, Attribute) of
        {ok, Value} ->
            Value;
        undefined ->
            Default
    end.
