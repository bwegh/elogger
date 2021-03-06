%%%----------------------------------------------------------------------
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
%% ---------------------------------
%% Logging mechanism

%% Print in standard output
-define(PRINT(Format, Args),
    io:format(Format, Args)).

-define(DEBUG(Format, Args),
    elogger:debug(?MODULE,?LINE,Format, Args)).

-define(DBG(Format, Args),
    elogger:debug(?MODULE,?LINE,Format, Args)).

-define(INFO(Format, Args),
    elogger:info(?MODULE,?LINE,Format, Args)).
			      
-define(WARNING(Format, Args),
    elogger:warning(?MODULE,?LINE,Format, Args)).
			      
-define(ERROR(Format, Args),
    elogger:error(?MODULE,?LINE,Format, Args)).

-define(CRITICAL(Format, Args),
    elogger:critical(?MODULE,?LINE,Format, Args)).
