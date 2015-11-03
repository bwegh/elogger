# elogger
copy of ejabber_log with a bit of renaming/changes.

```Erlang
elogger_config:set_loglevel(info).
elogger_config:add_file_logging("logfile.log").
```

In your module:
```Erlang
-include("elogger.hrl").

?DEBUG("say hello to the ~p",[world]).
```
