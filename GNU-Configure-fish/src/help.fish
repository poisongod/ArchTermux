# 帮助信息 / Help Messages
function _显示帮助
    if string match -qr "zh_CN*" $LANG
        echo "用法: configure.fish [选项] [命令...]"
        echo "选项:"
        echo "  --arch=arm/arm64      指定目标架构（默认：主机架构）"
        echo "  --toolchain-version=V 设置Arm工具链版本（默认：12.2）"
        echo "  --local-deps=PATH     指定本地依赖路径"
        echo "  --debug               启用调试日志"
        echo "  --help                显示此帮助信息"
    else
        echo "Usage: configure.fish [OPTION] [COMMAND...]"
        echo "Options:"
        echo "  --arch=arm/arm64      Target architecture (default: host)"
        echo "  --toolchain-version=V Set Arm toolchain version (default: 12.2)"
        echo "  --local-deps=PATH     Specify local dependencies path"
        echo "  --debug               Enable debug logging"
        echo "  --help                Show this help message"
    end
end