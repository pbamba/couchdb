-module(mango_index).


-export([
    create/3,
    delete/3,
    list/3
]).


-include_lib("couch/include/couch_db.hrl").


create(Db, Index, Opts) ->
    Idx = mango_idx:new(Index, Opts),
    {ok, DDoc} = load_ddoc(Db, mango_idx:ddoc(Idx)),
    case mango_idx:add(DDoc, Idx) of
        {ok, DDoc} ->
            {ok, <<"exists">>};
        {ok, NewDDoc} ->
            case mango_crud:insert(Db, NewDDoc, Opts) of
                {ok, _} ->
                    {ok, <<"created">>};
                _ ->
                    ?MANGO_ERROR(error_saving_ddoc)
            end
    end.


list(DbName) ->
    {ok, DDocs0} = mango_util:open_ddocs(DbName),
    Pred = fun({Props}) ->
        case proplists:get_value(<<"language">>, Props) of
            <<"mango">> -> true;
            _ -> false
        end
    end,
    DDocs = lists:filter(Pred, DDocs0),
    lists:flatmap(fun(Doc) ->
        mango_idx:from_ddoc(DbName, Doc)
    end, DDocs).


load_ddoc(Db, DDocId) ->
    case mango_util:open_doc(Db, DDocId) of
        {ok, Doc} ->
            {ok, Doc};
        not_found ->
            {ok, #doc{id = ddoc_id(Opts0), body = {[]}}}
    end.