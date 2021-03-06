%%%----------------------------------------------------------------------
%%% File    : ejabberd_loglevel.erl
%%% Author  : Mickael Remond <mremond@process-one.net>
%%% Purpose : Loglevel switcher.
%%%           Be careful: you should not have any ejabberd_logger module
%%%           as ejabberd_loglevel switcher is compiling and loading
%%%           dynamically a "virtual" ejabberd_logger module (Described
%%%           in a string at the end of this module).
%%% Created : 29 Nov 2006 by Mickael Remond <mremond@process-one.net>
%%%
%%%
%%% ejabberd, Copyright (C) 2002-2009   ProcessOne
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with this program; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%%% 02111-1307 USA
%%%
%%%----------------------------------------------------------------------

% -module(ejabberd_loglevel).
-module(elogger_config).
-author('mickael.remond@process-one.net').

-export([set_loglevel/1, get_loglevel/0, add_file_logging/1]).

-include("elogger.hrl").

-define(LOGMODULE, "error_logger").

%% Error levels:
-define(LOG_LEVELS,[ {0, no_log, "Off"}
                    ,{1, critical, "Critical"}
                    ,{2, error, "Error"}
                    ,{3, warning, "Warning"}
                    ,{4, info, "Info"}
                    ,{5, debug, "Debug"}
                    ]).

get_loglevel() ->
    Level = elogger:get(),
    case lists:keysearch(Level, 1, ?LOG_LEVELS) of
        {value, Result} -> Result;
        _ -> erlang:error({no_such_loglevel, Level})
    end.


set_loglevel(LogLevel) when is_list(LogLevel) ->
    set_loglevel(level_to_integer(LogLevel));
set_loglevel(LogLevel) when is_atom(LogLevel) ->
    set_loglevel(level_to_integer(LogLevel));
set_loglevel(Loglevel) when is_integer(Loglevel) ->
    try
        {Mod,Code} = elogger_dc:from_string(elogger_src(Loglevel)),
        code:load_binary(Mod, ?LOGMODULE ++ ".erl", Code)
    catch
        Type:Error -> ?CRITICAL("Error compiling logger (~p): ~p~n", [Type, Error])
    end;
set_loglevel(_) ->
    exit("Loglevel must be an integer").

level_to_integer(Level) when is_list(Level) ->
    case lists:keysearch(Level, 3, ?LOG_LEVELS) of
        {value, {Int, _Atom, Level}} -> Int;
        _ -> erlang:error({no_such_loglevel, Level})
    end;
level_to_integer(Level) ->
    case lists:keysearch(Level, 2, ?LOG_LEVELS) of
        {value, {Int, Level, _Desc}} -> Int;
        _ -> erlang:error({no_such_loglevel, Level})
    end.

add_file_logging(File) ->
  error_logger:add_report_handler(elogger_file_handler, File).

%% --------------------------------------------------------------
%% Code of the ejabberd logger, dynamically compiled and loaded
%% This allows to dynamically change log level while keeping a
%% very efficient code.
elogger_src(Loglevel) ->
    L = integer_to_list(Loglevel),
    "-module(elogger).
    %-module(ejabberd_logger).
    -author('mickael.remond@process-one.net').

    -export([debug/4,
             info/4,
             warning/4,
             error/4,
             critical/4,
             get/0]).

   get() -> "++ L ++".

    %% Helper functions
    debug(Module, Line, Format, Args) when " ++ L ++ " >= 5 ->
            notify(info_msg,
                   \"D(~p:~p:~p) : \"++Format++\"~n\",
                   [self(), Module, Line]++Args);
    debug(_,_,_,_) -> ok.

    info(Module, Line, Format, Args) when " ++ L ++ " >= 4 ->
            notify(info_msg,
                   \"I(~p:~p:~p) : \"++Format++\"~n\",
                   [self(), Module, Line]++Args);
    info(_,_,_,_) -> ok.

    warning(Module, Line, Format, Args) when " ++ L ++ " >= 3 ->
            notify(warning_msg,
                   \"W(~p:~p:~p) : \"++Format++\"~n\",
                   [self(), Module, Line]++Args);
    warning(_,_,_,_) -> ok.

    error(Module, Line, Format, Args) when " ++ L ++ " >= 2 ->
            notify(error,
                   \"E(~p:~p:~p) : \"++Format++\"~n\",
                   [self(), Module, Line]++Args);
    error(_,_,_,_) -> ok.

    critical(Module, Line, Format, Args) when " ++ L ++ " >= 1 ->
            notify(error,
                   \"*** CRIT ***(~p:~p:~p) : \"++Format++\"~n\",
                   [self(), Module, Line]++Args);
    critical(_,_,_,_) -> ok.

    %% Distribute the message to the Erlang error logger
    notify(Type, Format, Args) ->
            LoggerMsg = {Type, group_leader(), {self(), Format, Args}},
            gen_event:notify(error_logger, LoggerMsg).
    ".
