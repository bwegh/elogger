# elogger
copy of ejabber_log with a bit of renaming/changes.

```Erlang
elogger_loglevel:set(4).
error_logger:add_report_handler(elogger_file_handler, "logfile.log");
```

In your module:
```Erlang
-include("elogger.hrl").

?DEBUG("say hello to the ~p",[world]).
```
