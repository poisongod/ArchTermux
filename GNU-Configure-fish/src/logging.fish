# 日志系统 / Logging System
function _记录日志
    set -l level (string upper $argv[1])
    set -l message $argv[2]
    set -l logfile "$LOCALSTATEDIR/log/configure.log"

    if not test -d (dirname $logfile)
        mkdir -p (dirname $logfile)
    end

    if string match -qr "zh_CN*" $LANG
        echo "[$(date)] [$level] $message" >> $logfile
    else
        echo "[$(date)] [$level] $message" >> $logfile
    end
end

function _错误退出
    set -l message $argv[1]
    _记录日志 "ERROR" $message
    if string match -qr "zh_CN*" $LANG
        echo "错误: $message"
    else
        echo "Error: $message"
    end
    exit 1
end