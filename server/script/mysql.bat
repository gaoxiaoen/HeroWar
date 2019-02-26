@echo off

rem ---------------------------------------------------------
rem 控制脚本
rem @author kqqsysu@gmail.com
rem ---------------------------------------------------------

rem 参数
set PASSWORD=123456
set ACCOUNT=root
set MYSQL=C:\phpStudy\PHPTutorial\MySQL\bin\mysql.exe -u%ACCOUNT% -p%PASSWORD%
set MYSQLDUMP=C:\phpStudy\PHPTutorial\MySQL\bin\mysqldump.exe -u%ACCOUNT% -p%PASSWORD%


set inp=%1
if "%inp%" == "" goto fun_wait_input
goto fun_run

:fun_wait_input
    set inp=
    echo.
    echo ==============================
    echo create:创建数据库
    echo copyy:复制数据库结构
    echo batch:批量执行
    echo account:重置账号
    echo ------------------------------
    set /p inp=请输入指令:
    echo ------------------------------
    goto fun_run

:where_to_go
    rem 区分是否带有命令行参数
    if [%1]==[] goto fun_wait_input
    goto end

:fun_run
    if [%inp%]==[create] goto fun_create
    if [%inp%]==[copyy] goto fun_copy
    if [%inp%]==[batch] goto fun_batch
    if [%inp%]==[account] goto fun_account
    goto where_to_go


:fun_create
    set /p data=请输入数据库名字:

    %MYSQL% -e "drop database if exists %data%"
    %MYSQL% -e "create database %data%"
    echo 创建完毕
    goto where_to_go

:fun_batch
    set /p dir=请输入目录:
    set /p data=执行的数据库:
    for /R %dir% %%s in (.,*) do ( 
        %MYSQL% "%data%" < %%s
        echo %%s
    ) 
    echo 创建完毕
    goto where_to_go

:fun_copy
    set /p source=源数据库:
    set /p target=目标数据库:
    echo 正在导出结构......
    %MYSQLDUMP% --opt -d "%source%" > "%source%.sql"
    echo "已导出%source%.sql，正在导入结构......"
    %MYSQL% "%target%" < "%source%.sql"
    echo 复制数据库结构完毕
    goto where_to_go

:fun_account
    set /p data=请输入数据库名字:
    %MYSQL% "%data%" -e "update player_login inner join(select @rownum:=@rownum+1 as rank,player_state.pkey,player_state.cbp from player_state join (select @rownum:=0) as r order by player_state.cbp desc) c on player_login.pkey=c.pkey set player_login.accname = c.rank;update player_login set channel_id=11111,game_id=11111,game_channel_id=11111;"
    echo ------ 账号名字已经改为战力排行序号 ------
    goto where_to_go

:end