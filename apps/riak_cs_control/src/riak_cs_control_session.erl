%% -------------------------------------------------------------------
%%
%% Copyright (c) 2007-2012 Basho Technologies, Inc.  All Rights Reserved.
%%
%% -------------------------------------------------------------------

%% @author Christopher Meiklejohn <cmeiklejohn@basho.com>
%% @copyright 2012 Basho Technologies, Inc.

%% @doc Generic server for performing Riak CS operations.

-module(riak_cs_control_session).
-author('Christopher Meiklejohn <cmeiklejohn@basho.com>').

-behaviour(gen_server).

-type keyid() :: string().
-type attributes() :: string().

%% API
-export([start_link/0,
         get_users/0,
         get_user/1,
         put_user/1,
         put_user/2]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-define(SERVER, ?MODULE).

-define(DEFAULT_ADMIN_KEY, <<"admin-key">>).

-record(state, {cs_host :: binary(),
                cs_port :: non_neg_integer(),
                proto :: string(),
                access_key_id :: binary(),
                secret_access_key :: binary()
               }).
%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

-spec get_users() -> {ok, [string()]} | {error, term()}.
get_users() ->
    gen_server:call(?MODULE, list_users, infinity).

-spec get_user(keyid()) -> {ok, binary()} | {error, term()}.
get_user(KeyId) ->
    gen_server:call(?MODULE, {get_user, KeyId}, infinity).

-spec put_user(attributes()) -> {ok, binary()} | {error, term()}.
put_user(Attributes) ->
    gen_server:call(?MODULE, {put_user, Attributes}, infinity).

-spec put_user(keyid(), attributes()) -> {ok, binary()} | {error, term()}.
put_user(KeyId, Attributes) ->
    gen_server:call(?MODULE, {put_user, KeyId, Attributes}, infinity).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    Host = riak_cs_control_configuration:get(cs_host),
    Port = riak_cs_control_configuration:get(cs_port),
    Proto = riak_cs_control_configuration:get(cs_proto),
    AdminKeyId = riak_cs_control_configuration:get(cs_admin_key),
    AdminKeySecret = riak_cs_control_configuration:get(cs_admin_secret),
    {ok, #state{cs_host = Host,
                cs_port = Port,
                proto = Proto,
                access_key_id = AdminKeyId,
                secret_access_key = AdminKeySecret}}.

handle_call(Request, _From, State = #state{cs_host = Host,
                                           cs_port = Port,
                                           proto = Proto}) ->
    BaseUrl = io_lib:format("~s://~s:~b", [Proto, Host, Port]),
    case handle_request(Request, BaseUrl, State) of
        {ok, Response} ->
            {reply, {ok, Response}, State};
        Error ->
            {reply, Error, State}
    end.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% @doc Handle get/put requets.
handle_request(list_users, BaseUrl, State) ->
    list_users(BaseUrl, State);
handle_request({get_user, KeyId}, BaseUrl, State) ->
    get_user(BaseUrl, KeyId, State);
handle_request({put_user, KeyId, User}, BaseUrl, State) ->
    #{<<"user">> := UserItems} = jsx:decode(User),
    update_user(BaseUrl, KeyId, UserItems, State);
handle_request({put_user, User}, BaseUrl, State) ->
    #{<<"user">> := #{<<"email">> := Email,
                      <<"name">> := Name}} = jsx:decode(User),
    create_user(BaseUrl, Email, Name, State).



get_user(BaseUrl, KeyId, #state{access_key_id = AdmKeyId,
                                secret_access_key = AdmSAK}) ->
    Resource = "/riak-cs/user/" ++ KeyId,
    Url = BaseUrl ++ Resource,
    Headers = make_headers(AdmKeyId, AdmSAK, get, [], [], Resource)
        ++ [{"accept", "application/json"}],
    case httpc:request(get, {Url, Headers},
                       [], [{full_result, false}]) of
        {ok, {200, Body}} ->
            {ok, jsx:decode(Body)};
        {ok, {_, Non200, Body}} ->
            logger:warning("get_user(~s) failed with code ~b: ~s", [KeyId, Non200, Body]),
            {error, Body}
    end.

create_user(BaseUrl, EmailAddr, Name, #state{access_key_id = ?DEFAULT_ADMIN_KEY}) ->
    ReqBody = jsx:encode(#{<<"email">> => EmailAddr,
                             <<"name">> => Name}),
    ContentType = "application/json",
    Resource = "/riak-cs/user",
    Url = BaseUrl ++ Resource,
    Headers = [{"accept", "application/json"}],
    case httpc:request(post, {Url, Headers, ContentType, ReqBody},
                       [], [{full_result, false}]) of
        {ok, {201, Body}} ->
            {ok, jsx:decode(Body)};
        {ok, {409, _Body}} ->
            {error, user_already_exists};
        {ok, {Non200, Body}} ->
            logger:warning("create_user(~s) failed with code ~b: ~s", [EmailAddr, Non200, Body]),
            {error, Body}
    end;
create_user(BaseUrl, EmailAddr, Name, #state{access_key_id = KeyId,
                                             secret_access_key = SAK}) ->
    ReqBody = jsx:encode(#{<<"email">> => EmailAddr,
                           <<"name">> => Name}),
    ContentType = "application/json",
    CMD5 = binary_to_list(base64:encode(crypto:hash(md5, ReqBody))),
    Resource = "/riak-cs/user",
    Url = BaseUrl ++ Resource,
    Headers = make_headers(KeyId, SAK, post, CMD5, ContentType, Resource)
        ++ [{"accept", "application/json"}],
    case httpc:request(post, {Url, Headers, ContentType, ReqBody},
                       [], [{full_result, false}]) of
        {ok, {201, Body}} ->
            {ok, jsx:decode(Body)};
        {ok, {409, _Body}} ->
            {error, user_already_exists};
        {ok, {Non200, Body}} ->
            logger:warning("create_user(~s) failed with code ~b: ~s", [EmailAddr, Non200, Body]),
            {error, Body}
    end.

update_user(BaseUrl, KeyId, UserItems, #state{access_key_id = AdmKeyId,
                                              secret_access_key = AdmSAK}) ->
    ReqBody = jsx:encode(UserItems),
    Resource = io_lib:format("/riak-cs/user/~s", [KeyId]),
    Url = BaseUrl ++ Resource,
    ContentType = "application/json",
    CMD5 = binary_to_list(base64:encode(crypto:hash(md5, ReqBody))),
    Headers = make_headers(AdmKeyId, AdmSAK,
                           put, CMD5, ContentType, Resource)
        ++ [{"accept", "application/json"}],
    case httpc:request(put, {Url, Headers, ContentType, ReqBody},
                       [], [{full_result, false}]) of
        {ok, {200, RespBody}} ->
            {ok, jsx:decode(RespBody)};
        {ok, {Non200, RespBody}} ->
            logger:warning("update_user(~s) failed with code ~b: ~s", [KeyId, Non200, RespBody]),
            {error, RespBody}
    end.

list_users(BaseUrl, #state{access_key_id = AdmKeyId,
                           secret_access_key = AdmSAK}) ->
    Resource = "/riak-cs/users",
    Url = BaseUrl ++ Resource,
    Headers = make_headers(AdmKeyId, AdmSAK, get, [], [], Resource)
        ++ [{"accept", "application/json"}],
    case httpc:request(get, {Url, Headers}, [], []) of
        {ok, {{_, 200, _}, _RespHeaders, Body}} ->
            Parts =
                %% split a series of multipart documents
                case re:run(Body, "(?:\r\n--.+\r\nContent-Type: application/json\r\n\r\n(.+)\r\n--.+)+",
                            [{capture, all_but_first, binary}]) of
                    {match, Many} ->
                        Many;
                    [] ->
                        []
                end,
            Decoded = [jsx:decode(P) || P <- Parts],
            {ok, lists:append(Decoded)};
        {ok, {Non200, Body}} ->
            logger:warning("list_users failed with code ~b: ~p", [Non200, Body]),
            {error, Body}
    end.


make_headers(AccessKeyId, SecretAccessKey,
             Method, ContentMD5, ContentType, Resource) ->
    Date = iso_8601_format_now(),
    [{"authorization", make_authorization(
                         AccessKeyId, SecretAccessKey, Method,
                         ContentMD5, ContentType, Date, [],
                         Resource)},
     {"date", Date},
     {"accept", "application/json"}
    ]   ++ [{"content-md5", ContentMD5} || ContentMD5 =/= []]
        ++ [{"content-type", ContentType} || ContentType =/= []].

make_authorization(AccessKeyId, SecretAccessKey,
                   Method, ContentMD5, ContentType,
                   Date, AmzHeaders,
                   Resource) ->
    StringToSign = [string:to_upper(atom_to_list(Method)), $\n,
                    ContentMD5, $\n,
                    ContentType, $\n,
                    Date, $\n,
                    AmzHeaders,
                    "",
                    Resource,
                    []
                   ],
    %% logger:debug("STS:  ~p", [StringToSign]),
    Signature = base64:encode(crypto:mac(hmac, sha, SecretAccessKey, StringToSign)),
    ["AWS ", AccessKeyId, $:, Signature].

iso_8601_format_now() ->
    {{Y, Mo, D}, {H, Mi, S}} = calendar:universal_time(),
    iso_8601_format(Y, Mo, D, H, Mi, S).
iso_8601_format(Year, Month, Day, Hour, Min, Sec) ->
    lists:flatten(
      io_lib:format("~4.10.0B-~2.10.0B-~2.10.0BT~2.10.0B:~2.10.0B:~2.10.0B.000Z",
                    [Year, Month, Day, Hour, Min, Sec])).
