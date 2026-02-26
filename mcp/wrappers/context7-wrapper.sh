#!/bin/bash
# Context7 MCP 服务器包装脚本
# 确保在 nvm 环境中运行

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

# 运行 Context7 MCP 服务器
exec npx -y @upstash/context7-mcp "$@"
