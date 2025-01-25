# 交叉编译配置 / Cross-Compilation Setup
function _配置Arm工具链
    set -l version (default $_flag_toolchain_version "12.2")
    set -l url "https://developer.arm.com/.../arm-gnu-toolchain-$version-$ARCH.tar.xz"

    if not test -d "arm-gnu-toolchain"
        wget -q $url -O toolchain.tar.xz || return 1
        tar -xf toolchain.tar.xz || return 1
        mv arm-gnu-toolchain-* arm-gnu-toolchain || return 1
    end

    set -gx PATH "$PWD/arm-gnu-toolchain/bin:$PATH"
    set -gx CC "$ARCH-linux-gnu-gcc"
    set -gx HOST "$ARCH-linux-gnu"
    _记录日志 "INFO" "工具链配置完成: $ARCH / Toolchain configured: $ARCH"
    return 0
end