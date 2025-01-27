#!/bin/sh

# 定义 Fish 补全脚本内容
FISH_COMPLETION_SCRIPT='
# Fish Shell 自动补全：configure-wrapper
function __configure_wrapper_get_configure_args
    set -l cmd (commandline -poc)
    set -e cmd[1]
    set -l configure_script "../configure"
    for i in (seq 1 (count $cmd))
        if string match -q -- "--configure-script=*" $cmd[$i]
            set configure_script (string split -m1 = -- $cmd[$i])[2]
            break
        end
    end
    if test -f "$configure_script"
        "$configure_script" --help 2>&1 | grep -oE "--[a-zA-Z0-9-]+(=?[^ ]*)?" | sed "s/[[:space:]]*$//"
    end
end

complete -c configure-wrapper -f
complete -c configure-wrapper -n "__fish_use_subcommand" -l system-root -d "目标系统根目录" -F
complete -c configure-wrapper -n "__fish_use_subcommand" -l configure-script -d "指定 configure 脚本路径" -r
complete -c configure-wrapper -n "__fish_seen_subcommand_from (__configure_wrapper_get_configure_args)" -a "(__configure_wrapper_get_configure_args)"
'

# 安装 Fish 补全
install_fish_completion() {
    completion_dir="$HOME/.config/fish/completions"
    completion_file="$completion_dir/configure-wrapper.fish"
    
    mkdir -p "$completion_dir"
    echo "$FISH_COMPLETION_SCRIPT" > "$completion_file"
    echo "Fish 补全已安装至: $completion_file"
}

# 显示脚本帮助信息
show_help() {
    echo "用法: configure.fish [选项]"
    echo "选项:"
    echo "  --system-root=DIR       设置目标系统根目录"
    echo "  --configure-script=FILE 指定 configure 脚本路径"
    echo "  --install-completions   安装 Fish 补全"
    echo "  --help                  显示此帮助信息"
    echo "  --help-configure        显示原生 configure 脚本的帮助信息"
    echo ""
    echo "示例:"
    echo "  configure.fish --system-root=/data/data/com.termux/files --host=aarch64-none-linux-gnu"
    echo "  configure.fish --help-configure"
}

# 显示原生 configure 帮助信息
show_configure_help() {
    if [ -f "$CONFIGURE_SCRIPT" ]; then
        "$CONFIGURE_SCRIPT" --help
    else
        echo "错误：找不到 configure 脚本！路径：$CONFIGURE_SCRIPT" >&2
        exit 1
    fi
}

# 主逻辑：配置和构建
main() {
    # 解析参数
    SYSTEM_ROOT=""
    EXTRA_ARGS=""
    CONFIGURE_SCRIPT="../configure"  # 默认路径

    while [ $# -gt 0 ]; do
        case "$1" in
            --system-root=*)
                SYSTEM_ROOT="${1#*=}"
                shift
                ;;
            --configure-script=*)
                CONFIGURE_SCRIPT="${1#*=}"
                shift
                ;;
            --install-completions)
                install_fish_completion
                exit 0
                ;;
            --help)
                show_help
                exit 0
                ;;
            --help-configure)
                show_configure_help
                exit 0
                ;;
            *)
                # 修复点：避免 EXTRA_ARGS 开头出现多余空格
                if [ -z "$EXTRA_ARGS" ]; then
                    EXTRA_ARGS="$1"
                else
                    EXTRA_ARGS="$EXTRA_ARGS $1"
                fi
                shift
                ;;
        esac
    done

    # 处理路径
    SYSTEM_ROOT="${SYSTEM_ROOT:-$(pwd)/system_root}"
    case "$SYSTEM_ROOT" in
        /*) ;;
        *) SYSTEM_ROOT="$(pwd)/$SYSTEM_ROOT" ;;
    esac
    case "$CONFIGURE_SCRIPT" in
        /*) ;;
        *) CONFIGURE_SCRIPT="$(pwd)/$CONFIGURE_SCRIPT" ;;
    esac

    # 检查 configure 脚本
    if [ ! -f "$CONFIGURE_SCRIPT" ]; then
        echo "错误：找不到 configure 脚本！路径：$CONFIGURE_SCRIPT" >&2
        exit 1
    fi

    # 调试信息：打印参数
    echo "SYSTEM_ROOT: $SYSTEM_ROOT"
    echo "CONFIGURE_SCRIPT: $CONFIGURE_SCRIPT"
    echo "EXTRA_ARGS: $EXTRA_ARGS"

    # 创建目标系统目录
    mkdir -p "$SYSTEM_ROOT/usr/bin"
    mkdir -p "$SYSTEM_ROOT/usr/lib"
    mkdir -p "$SYSTEM_ROOT/usr/include"
    mkdir -p "$SYSTEM_ROOT/etc"
    mkdir -p "$SYSTEM_ROOT/var"

    # 设置环境变量，确保编译器和链接器使用目标系统目录
    export CC="aarch64-none-linux-gnu-gcc"
    export CXX="aarch64-none-linux-gnu-g++"
    export LD="aarch64-none-linux-gnu-ld"
    export AR="aarch64-none-linux-gnu-ar"
    export RANLIB="aarch64-none-linux-gnu-ranlib"
    export CFLAGS="-I$SYSTEM_ROOT/usr/include"
    export LDFLAGS="-L$SYSTEM_ROOT/usr/lib -Wl,-rpath-link,$SYSTEM_ROOT/usr/lib"

    # 运行 configure
    "$CONFIGURE_SCRIPT" \
        --prefix="$SYSTEM_ROOT/usr" \
        --sysconfdir="$SYSTEM_ROOT/etc" \
        --localstatedir="$SYSTEM_ROOT/var" \
        --bindir="$SYSTEM_ROOT/usr/bin" \
        --sbindir="$SYSTEM_ROOT/usr/sbin" \
        --libdir="$SYSTEM_ROOT/usr/lib" \
        --includedir="$SYSTEM_ROOT/usr/include" \
        --datarootdir="$SYSTEM_ROOT/usr/share" \
        --mandir="$SYSTEM_ROOT/usr/share/man" \
        --infodir="$SYSTEM_ROOT/usr/share/info" \
        --with-sysroot="$SYSTEM_ROOT" \
        $EXTRA_ARGS

    if [ $? -ne 0 ]; then
        echo "错误：configure 配置失败！" >&2
        exit 1
    fi

    # 编译并安装到目标系统目录
    make -j$(nproc)
    if [ $? -ne 0 ]; then
        echo "错误：编译失败！" >&2
        exit 1
    fi

    make install -j$(nproc)
    if [ $? -ne 0 ]; then
        echo "错误：安装到目标系统目录失败！" >&2
        exit 1
    fi

    echo "编译和安装完成！所有文件已安装到目标系统目录：$SYSTEM_ROOT"
}

# 执行主函数或安装补全
if [ "$1" = "--install-completions" ]; then
    install_fish_completion
else
    main "$@"
fi
