# 依赖检测与回退 / Dependency Check and Fallback
function _检测并回退依赖库
    set -l cmd_path $argv[1]
    set -gx TEMP_LD_LIBRARY_PATH ""

    # 检查是否为动态可执行文件
    if not ldd "$cmd_path" &>/dev/null
        _记录日志 "WARN" "非动态可执行文件: $cmd_path / Not a dynamic executable: $cmd_path"
        return 0
    end

    # 解析依赖库
    set -l libs (ldd "$cmd_path" | awk '/=>/ {print $1}' | grep -v 'linux-vdso')
    for lib in $libs
        set -l found 0
        # 检查 PREFIX 路径
        for dir in $LIBDIR $PREFIX/usr/lib
            if test -f "$dir/$lib"
                set found 1
                break
            end
        end
        # 回退到系统路径
        if test $found -eq 0
            set -l system_path (find /lib /usr/lib /usr/local/lib -name "$lib" 2>/dev/null | head -n1)
            if test -n "$system_path"
                set -gx TEMP_LD_LIBRARY_PATH "$TEMP_LD_LIBRARY_PATH":"(dirname $system_path)"
                _记录日志 "INFO" "回退到系统库: $lib / Fallback to system library: $lib"
            else
                _错误退出 "缺失依赖库: $lib / Missing library: $lib"
            end
        end
    end

    # 更新 LD_LIBRARY_PATH
    if set -q TEMP_LD_LIBRARY_PATH[1]
        set -gx LD_LIBRARY_PATH (string trim -l ':' "$TEMP_LD_LIBRARY_PATH") "$LD_LIBRARY_PATH"
    end
    return 0
end