@echo off

rem ---------------------------------------------------------
rem 控制脚本
rem @author kqqsysu@gmail.com
rem ---------------------------------------------------------

rem erl代码目录
set DIR_ERL=%~dp0
set EBIN_DIR=""
set WERL="%EBIN_DIR%werl"
set ERL="%EBIN_DIR%erl"
set ESCRIPT="%EBIN_DIR%escript"

rem 游戏启动统一配置
set OPENTIME=1508384824
set TICK="3e1f8f56ad582a7e76f8ef8adef0a54c"
set LOG_LEVEL=6
set DEBUG=1
set DB_HOST="127.0.0.1"
set DB_PORT=3306
set DB_USER="root"
set DB_PASS="123456"
set OS="win"
set IP="192.168.32.161"
SET ERL_COOKIE="onhook_dev"
SET KF_COOKIE="czjy"


rem 主节点相关设置
set GAME=onhook_dev
set SERVER_NUM=1
set PORT=8011
set DB_NAME="czjy"



rem 跨服节点相关配置
set KF_GAME=center_qztx0
set KF_SERVER_NUM=50001
set KF_PORT=8002


rem 跨服节点2相关配置
set KF_GAME2=center_qztx1
set KF_SERVER_NUM2=50002
set KF_PORT2=8003



rem 多核编译进程数
set MMAKER_PROCESS=16

set inp=%1
if "%inp%" == "" goto fun_wait_input
goto fun_run

:fun_wait_input
    set inp=
    echo.
    echo ==============================
    echo make: 编译服务端源码
    echo data: 生成配置表
    echo start: 启动游戏节点
    echo center: 启动center节点
    echo center2: 启动center2节点
    echo stop: 关闭服务器
    echo kill: 强行kill掉所有werl.exe进程
    echo dialyzer: dialyzer分析
    echo dialyzer_win: dialyzer分析
	  echo filter_log: 日志过滤分析
    echo clean: 清理erlang编译结果
    echo quit: 结束运行
	  echo ctags: 生成vim tags
	  echo proto: 生成协议
    echo edoc: 生成html文档
    echo ------------------------------
    set /p inp=请输入指令:
    echo ------------------------------
    goto fun_run

:where_to_go
    rem 区分是否带有命令行参数
    if [%1]==[] goto fun_wait_input
    goto end

:fun_run
    if [%inp%]==[make] goto fun_make
	  if [%inp%]==[data] goto fun_data
    if [%inp%]==[start] goto fun_start_start
    if [%inp%]==[center] goto fun_start_center
    if [%inp%]==[center2] goto fun_start_center2
    if [%inp%]==[stop] goto fun_stop_server
    if [%inp%]==[kill] goto fun_kill
    if [%inp%]==[clean] goto fun_clean
	  if [%inp%]==[dialyzer] goto fun_dialyzer
	  if [%inp%]==[dialyzer_win] goto fun_dialyzer_win
	  if [%inp%]==[filter_log] goto fun_filter_log
	  if [%inp%]==[ctags] goto fun_ctags
	  if [%inp%]==[proto] goto fun_proto
      if [%inp%]==[edoc] goto fun_edoc
    if [%inp%]==[quit] goto end
    goto where_to_go


:fun_make
    rem 编译命令
	  call :fun_mmaker 
    set arg=
    cd %DIR_ERL%
	  goto fun_make_debug
    goto where_to_go

:fun_data
	cd %DIR_ERL%/../../excel
	call run.bat
	goto where_to_go
	
:fun_make_debug
    cd %DIR_ERL%/../
    %ERL% -pa ebin -noinput -eval "case mmake:all(%MMAKER_PROCESS%,[{outdir, \"ebin\"},{d,'DEBUG_BUILD'}])  of up_to_date -> halt(0); error -> halt(1) end. "
    goto where_to_go

:fun_start_start
    rem 启动主节点
    cd %DIR_ERL%/../config
    erl
		+P 204800 
		-smp enable 
		-pa ../ebin 
		-pa ../sbin 
		-name %GAME%@%IP% 
		-setcookie %ERL_COOKIE% 
		-boot start_sasl 
		-config server  
		-s game server_start 
		-extra %SERVER_NUM% %IP% %PORT% %OPENTIME% %TICK% %LOG_LEVEL% %DEBUG% %DB_HOST% %DB_PORT% %DB_USER% %DB_PASS% %DB_NAME% %OS%	
    pause
	goto where_to_go
	
:fun_start_center
    rem 启动跨服节点
    cd %DIR_ERL%/../config
    start "" "%WERL%" -hidden -kernel inet_dist_listen_min %ERL_PORT_MIN% -kernel inet_dist_listen_max %ERL_PORT_MAX% +P 204800 -smp enable -pa ../ebin -pa ../sbin -name %KF_GAME%@%IP% -setcookie %KF_COOKIE% -boot start_sasl -config server  -s game server_start -extra %KF_SERVER_NUM% %IP% %KF_PORT% %OPENTIME% %TICK% %LOG_LEVEL% %DEBUG% %DB_HOST% %DB_PORT% %DB_USER% %DB_PASS% %DB_NAME% %OS%
		goto where_to_go

:fun_start_center2
    rem 启动跨服节点2
    cd %DIR_ERL%/../config
    start "" "%WERL%" -hidden -kernel inet_dist_listen_min %ERL_PORT_MIN% -kernel inet_dist_listen_max %ERL_PORT_MAX% +P 204800 -smp enable -pa ../ebin -pa ../sbin -name %KF_GAME2%@%IP% -setcookie %KF_COOKIE% -boot start_sasl -config server  -s game server_start -extra %KF_SERVER_NUM2% %IP% %KF_PORT2% %OPENTIME% %TICK% %LOG_LEVEL% %DEBUG% %DB_HOST% %DB_PORT% %DB_USER% %DB_PASS% %DB_NAME% %OS%
		goto where_to_go

:fun_kill
    rem 强制kill掉werl.exe
    taskkill /F /IM werl.exe
    goto where_to_go

:fun_stop_server
    rem 关闭服务器
    start "" "%WERL%" -name %GAME%_stop@%IP% -setcookie %ERL_COOKIE% -eval "rpc:call('%GAME%@%IP%',game,server_stop,[]),erlang:halt(0)"
    goto where_to_go

:fun_clean
    cd %DIR_ERL%\ebin
    del *.beam
    echo 清理erlang编译结果完成
    goto where_to_go

:fun_dialyzer
	rem 清理beam
	cd %DIR_ERL%\ebin
    del *.beam
	cd %DIR_ERL%
	cd script
	ESCRIPT gen_data.erl
	cd %DIR_ERL%
	%ERL%  -pa ebin -noinput -eval "case make:files([\"src/tool/mmake.erl\"],[debug_info,{outdir, \"ebin\"}]) of up_to_date -> halt(0); _ -> halt(1) end."
	%ERL%  -pa ebin -noinput -eval "case make:files([\"src/mod/common/gen_server2.erl\"],[debug_info,{outdir, \"ebin\"}]) of up_to_date -> halt(0); _ -> halt(1) end."
	%ERL%  -pa ebin -noinput -eval "case make:files([\"src/mod/common/gen_server3.erl\"],[debug_info,{outdir, \"ebin\"}]) of up_to_date -> halt(0); _ -> halt(1) end."	
	%ERL%  -pa ebin -noinput -eval "case make:files([\"src/ts.erl\"],[debug_info,{outdir, \"ebin\"}]) of up_to_date -> halt(0); _ -> halt(1) end."
	cd %DIR_ERL%\ebin
	rem make debug
	cd %DIR_ERL%
    %ERL% -pa ebin -noinput -eval "case mmake:all(%MMAKER_PROCESS%,[debug_info,{outdir, \"ebin\"}]) of up_to_date -> halt(0); error -> halt(1) end."
	rem dialyzer
	dialyzer -Werror_handling -r %DIR_ERL%\ebin > %DIR_ERL%\dialyzer.txt
	echo 分析完毕
    goto where_to_go

:fun_dialyzer_win
    rem 清理beam
    if not exist %DIR_ERL%../ebin_debug (mkdir %DIR_ERL%..\ebin_debug)
    cd %DIR_ERL%../ebin_debug
    rem del *.beam
    cd %DIR_ERL%
    %ERL%  -pa ../ebin_debug -noinput -eval "case make:files([\"../src/tool/mmake.erl\"],[debug_info,{outdir, \"../ebin_debug\"}]) of up_to_date -> halt(0); _ -> halt(1) end."
    %ERL% -pa ../ebin_debug -noinput -eval "case mmake:all(%MMAKER_PROCESS%,[debug_info,{outdir, \"../ebin_debug\"}]) of up_to_date -> halt(0); error -> halt(1) end."
    rem dialyzer
    dialyzer -Werror_handling -r %DIR_ERL%..\ebin_debug > %DIR_ERL%dialyzer.txt
    echo 分析完毕
    goto where_to_go

:fun_filter_log
	cd %DIR_ERL%/../
	%ERL%  -pa ebin -eval "filter_log:filter(\"%LOG_FILE_PATH%\"),halt(0)"
	goto where_to_go
	
:fun_ctags
	cd %DIR_ERL%/../
	ctags -R
	goto where_to_go

:fun_proto
	cd %DIR_ERL%/../../proto
	call run.bat
	goto where_to_go

:fun_edoc
    cd %DIR_ERL%/../
    %ERL% -eval "case edoc:application(server, \"%DIR_ERL%/../\", []) of ok ->halt(0); _->halt(1) end"
    goto where_to_go
	

:fun_mmaker
	cd %DIR_ERL%/../
	%ERL%  -pa ebin -noinput -eval "case make:files([\"src/tool/mmake.erl\"],[{outdir, \"ebin\"}]) of up_to_date -> halt(0); _ -> halt(1) end."
	rem %ERL%  -pa ebin -noinput -eval "case make:files([\"src/mod/common/gen_server2.erl\"],[{outdir, \"ebin\"}]) of up_to_date -> halt(0); _ -> halt(1) end."
	rem %ERL%  -pa ebin -noinput -eval "case make:files([\"src/mod/common/gen_server3.erl\"],[{outdir, \"ebin\"},{i,\"include\"}]) of up_to_date -> halt(0); _ -> halt(1) end."	
	rem %ERL%  -pa ebin -noinput -eval "case make:files([\"src/ts.erl\"],[{outdir, \"ebin\"},{i,\"include\"}]) of up_to_date -> halt(0); _ -> halt(1) end."

:end

