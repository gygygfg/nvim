#!/bin/bash
# 通用 nvm 包装脚本
# 确保在 nvm 环境中运行任何 Node.js 命令

# 加载 nvm 环境
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    . "$HOME/.nvm/nvm.sh"
else
    echo "错误: 无法加载 nvm 环境" >&2
    exit 1
fi

# 确保使用正确的 Node.js 版本
if ! command -v node &> /dev/null; then
    echo "错误: Node.js 未找到，请检查 nvm 配置" >&2
    exit 1
fi

# 执行原始命令
exec "$@"
