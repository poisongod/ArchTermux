# 参数解析与补全 / Argument Parsing and Autocompletion
function _生成补全
    # 补全系统PATH命令
    complete -c configure.fish -x -a "(fish -c 'for p in (string split : \$PATH); ls \$p 2>/dev/null; end')" -d "系统命令 / System command"
    # 补全原生configure参数
    complete -c configure.fish -x -a "(./configure --help 2>/dev/null | awk '/--/ {print \$1}' | string trim)" -d "原生参数 / Native argument"
    # 脚本参数
    complete -c configure.fish -s h -l help -d "显示帮助 / Show help"
    complete -c configure.fish -s D -l debug -d "启用调试模式 / Enable debug"
    complete -c configure.fish -l arch -x -a "arm arm64" -d "目标架构 / Target architecture"
    complete -c configure.fish -l toolchain-version -x -d "工具链版本 / Toolchain version"
    complete -c configure.fish -l local-deps -r -d "本地依赖路径 / Local dependencies path"
end