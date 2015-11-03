# elogger
copy of ejabber_log with a bit of renaming/changes.

```Erlang
% important: must be called before starting to log!
elogger_config:set_loglevel(info).
% supported: debug, info, warning, error, critical, no_log
elogger_config:add_file_logging("logfile.log").
```

In your module:
```Erlang
-include("elogger.hrl"). % include the macros

?DEBUG("say hello to the ~p",[world]). % and use the macro 

elogger:debug("say hello to the ~p",[world]). %or just use the function
```
