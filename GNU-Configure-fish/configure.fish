#!/usr/bin/fish

# --- 加载模块 ---
source src/core_vars.fish
source src/args_parser.fish
source src/deps_check.fish
source src/cross_compile.fish
source src/logging.fish
source src/help.fish

# --- 初始化 ---
_配置路径
_生成补全
argparse \
    h/help \
    D/debug \
    arch= \
    toolchain-version= \
    local-deps= \
    -- $argv || _错误退出 "参数解析失败 / Failed to parse arguments"

# --- 显示帮助信息 ---
if set -q _flag_help
    _显示帮助
    exit 0
end

# --- 设置调试模式 ---
if set -q _flag_debug
    set -gx DEBUG 1
    _记录日志 "DEBUG" "启用调试模式 / Debug mode enabled"
end

# --- 依赖检查 ---
if set -q argv[1]
    for cmd in $argv
        if string match -qr "^/" "$cmd"
            set cmd_path "$cmd"
        else
            set cmd_path (command -v "$cmd")
            if test -z "$cmd_path"
                _错误退出 "命令不存在：$cmd / Command not found: $cmd"
            end
        end
        _检测并回退依赖库 "$cmd_path" || exit 1
    end
else
    # 默认检查关键依赖
    _检查依赖 autoconf automake libtool || _错误退出 "默认依赖缺失 / Missing default dependencies"
end

# --- 交叉编译配置 ---
if set -q _flag_arch
    set -gx ARCH $_flag_arch
    _配置Arm工具链 || _错误退出 "工具链配置失败 / Toolchain setup failed"
end

# --- 本地依赖路径设置 ---
if set -q _flag_local_deps
    set -gx LOCAL_DEPS (realpath $_flag_local_deps)
    _设置本地依赖路径
else
    _下载依赖库 || _错误退出 "依赖库下载失败 / Failed to download dependencies"
end

# --- 编译配置 ---
set -l configure_args \
    --prefix=$PREFIX \
    --bindir=$BINDIR \
    --sbindir=$SBINDIR \
    --libdir=$LIBDIR \
    --libexecdir=$LIBEXECDIR \
    --includedir=$INCLUDEDIR \
    --datarootdir=$DATAROOTDIR \
    --sysconfdir=$SYSCONFDIR \
    --localstatedir=$LOCALSTATEDIR \
    --runstatedir=$RUNSTATEDIR \
    $OVERRIDE_ARGS

# 设置 RPATH 确保 PREFIX 中的库可被找到
set -gx LDFLAGS "-Wl,-rpath,$LIBDIR $LDFLAGS"

# --- 调用原生configure脚本 ---
_记录日志 "INFO" "开始配置项目 / Starting project configuration"
env CC=$CC CFLAGS=$CFLAGS LDFLAGS=$LDFLAGS ./configure $configure_args

if test $status -eq 0
    _记录日志 "INFO" "配置成功 / Configuration succeeded"
else
    _错误退出 "配置失败 / Configuration failed"
end