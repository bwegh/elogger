%%%----------------------------------------------------------------------
%%% File    : ejabberd_logger_h.erl
%%% Author  : Alexey Shchepin <alexey@process-one.net>
%%% Purpose : Manage Erlang logging.
%%% Created : 23 Oct 2003 by Alexey Shchepin <alexey@process-one.net>
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
% -module(ejabberd_logger_h).
-module(elogger_file_handler).
-author('alexey@process-one.net').

-behaviour(gen_event).

%% gen_event callbacks
-export([init/1, handle_event/2, handle_call/2, handle_info/2, terminate/2,
	 code_change/3, reopen_log/0, rotate_log/1]).

-record(state, {fd, file}).

%%%----------------------------------------------------------------------
%%% Callback functions from gen_event
%%%----------------------------------------------------------------------

%%----------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok, State}          |
%%          Other
%%----------------------------------------------------------------------
init(File) ->
    case file:open(File, [append, raw]) of
	{ok, Fd} ->
	    {ok, #state{fd = Fd, file = File}};
	Error ->
	    Error
    end.

%%----------------------------------------------------------------------
%% Func: handle_event/2
%% Returns: {ok, State}                                |
%%          {swap_handler, Args1, State1, Mod2, Args2} |
%%          remove_handler                              
%%----------------------------------------------------------------------
handle_event(Event, State) ->
    write_event(State#state.fd, {erlang:localtime(), Event}),
    {ok, State}.

%%----------------------------------------------------------------------
%% Func: handle_call/2
%% Returns: {ok, Reply, State}                                |
%%          {swap_handler, Reply, Args1, State1, Mod2, Args2} |
%%          {remove_handler, Reply}                            
%%----------------------------------------------------------------------
handle_call(_Request, State) ->
    Reply = ok,
    {ok, Reply, State}.

%%----------------------------------------------------------------------
%% Func: handle_info/2
%% Returns: {ok, State}                                |
%%          {swap_handler, Args1, State1, Mod2, Args2} |
%%          remove_handler                              
%%----------------------------------------------------------------------
handle_info({'EXIT', _Fd, _Reason}, _State) ->
    remove_handler;
handle_info({emulator, _GL, reopen}, State) ->
    file:close(State#state.fd),
    rotate_log(State#state.file),
    case file:open(State#state.file, [append, raw]) of
	{ok, Fd} ->
	    {ok, State#state{fd = Fd}};
	Error ->
	    Error
    end;
handle_info({emulator, GL, Chars}, State) ->
    write_event(State#state.fd, {erlang:localtime(), {emulator, GL, Chars}}),
    {ok, State};
handle_info(_Info, State) ->
    {ok, State}.

%%----------------------------------------------------------------------
%% Func: terminate/2
%% Purpose: Shutdown the server
%% Returns: any
%%----------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

reopen_log() ->
    error_logger ! {emulator, noproc, reopen}.

%%%----------------------------------------------------------------------
%%% Internal functions
%%%----------------------------------------------------------------------

% Copied from erlang_logger_file_h.erl
write_event(Fd, {Time, {_, _GL, {Pid, Format, Args}}}) ->
  %very simple output ... just one line per log 
    T = write_time(Time),
    N = print_node(node(Pid)),
    Msg = io_lib:format(Format,Args),
    file:write(Fd,T++N++Msg);
write_event(_, _) ->
    ok.

write_time({{Y, Mo,D}, {H, Mi, S}}) ->
  io_lib:format("~w-~.2.0w-~.2.0w ~.2.0w:~.2.0w:~.2.0w ",[Y,Mo,D,H,Mi,S]).

print_node(Node) when is_atom(Node) ->
  print_node(atom_to_list(Node));
print_node(Node) when is_list(Node) ->
  io_lib:format("~s ",[Node]).

%% @doc Rename the log file if exists, to "*-old.log".
%% This is needed in systems when the file must be closed before rotation (Windows).
%% On most Unix-like system, the file can be renamed from the command line and
%% the log can directly be reopened.
%% @spec (Filename::string()) -> ok
rotate_log(Filename) ->
    case file:read_file_info(Filename) of
	{ok, _FileInfo} ->
	    RotationName = filename:rootname(Filename),
	    file:rename(Filename, [RotationName, "-old.log"]),
	    ok;
	{error, _Reason} ->
	    ok
    end.
	    
