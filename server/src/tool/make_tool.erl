%%----------------------------------------------------------------------
%%% @date   : 2015.07.20
%%% @desc   : 编译多个文件,如 make_tool:m(mod_server). make_tool:m([mod_server,mod_scene]).
%%%----------------------------------------------------------------------


-module(make_tool).

-include_lib("kernel/include/file.hrl").

-export([m/1,m/2,make_all/0,make_all/1]).

-define(BASE_PATH,"..").
-define(SRC_PATH,"../src").
-define(DEFAULT_OPTION,[{d,'DEBUG_BUILD'}]).

m(File) when is_atom(File) ->
    m([File],?DEFAULT_OPTION);
m(Files) ->
    m(Files,?DEFAULT_OPTION).

m(File,Options) when is_atom(File) ->
    m([File],Options);
m([File | T],Options) ->
    case get_file_path([?SRC_PATH],atom_to_list(File) ++ ".erl") of
        {ok,Path} ->
            make:files([Path],[{outdir, ?BASE_PATH ++ "/ebin"},{i,?BASE_PATH ++ "/include"}] ++ Options),
            reloader:reload_modules([File]);
        _ ->
            io:format("++++++++ Error:get file:~w path fail ++++++++~n",[File])
    end,
    m(T);
m([],_Options) ->
    ok.

get_file_path([Path | T],File) ->
    case file:list_dir(Path) of
        {ok,Files} ->
            %% 如果Files有目录继续找
            {NewDirList,FindPath} =
                lists:foldl(fun(F,{AccInDir,AccInFile}) ->
                    F2 = Path ++ "/" ++ F,
                    case F of
                        File ->
                            %% 找到了
                            {AccInDir,F2};
                        _ ->
                            case filelib:is_dir(F2) andalso string:str(F2,".svn") == 0 of
                                true ->
                                    {[F2 | AccInDir],AccInFile};
                                false ->
                                    {AccInDir,AccInFile}
                            end
                    end
                            end,{T,false},Files),
            case FindPath of
                false ->
                    get_file_path(NewDirList,File);
                _ ->
                    {ok,FindPath}
            end;
        _ ->
            get_file_path(T,File)
    end;
get_file_path([],_File) ->
    false.

%% 编译文件，IsForce不检查时间，直接编译所有.erl文件
make_all() ->
    make_all(false).
make_all(IsForce) ->
    Now = util:unixtime(),
    make_all([?SRC_PATH],Now,IsForce),
    u:u().
make_all([Path | T],Now,IsForce) ->
    case file:list_dir(Path) of
        {ok,Files} ->
            lists:foreach(fun(_FilePath) ->
                FilePath = Path ++ "./" ++ _FilePath,
                IsSvn = string:str(FilePath,".svn") > 0,
                IsDir = filelib:is_dir(FilePath),
                IsErlFile = string:str(FilePath,".erl") > 0 andalso (IsForce orelse is_new_file(FilePath,Now)),
                if IsSvn -> ok;
                    IsDir -> make_all([FilePath],Now,IsForce);
                    IsErlFile ->
                        make:files([FilePath],[{outdir, ?BASE_PATH ++ "/ebin"},{i,?BASE_PATH ++ "/include"}] ++ ?DEFAULT_OPTION);
                    true -> ok
                end
                          end,Files);
        _ -> ok
    end,
    make_all(T,Now,IsForce);
make_all([],_Now,_IsForce) -> ok.

is_new_file(File,Now) ->
    case file:read_file_info(File) of
        {ok,#file_info{mtime = Mtime}} ->
            MSec = util:unixtime(Mtime),
            (MSec + 1800) >= Now;
        _ -> false
    end.
