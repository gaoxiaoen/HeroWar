cd ../ebin
erl +P 102400 -smp enable -name sd1@127.0.0.1 -setcookie sd2 -mnesia extra_db_nodes ["'sd1@127.0.0.1'"] ^
-boot start_sasl -config log  -s sd gateway_start -extra 127.0.0.1 6666 1
pause