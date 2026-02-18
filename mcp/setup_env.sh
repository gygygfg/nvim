#!/bin/sh
# MCP 环境变量设置脚本
# 运行: . ~/.config/nvim/mcp/setup_env.sh

# Context7 API Key
export CONTEXT7_API_KEY="ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07"

# 其他 MCP 服务器环境变量（根据需要设置）
# export GITHUB_TOKEN="your_github_token_here"
# export BRAVE_API_KEY="your_brave_api_key_here"

# 显示设置的环境变量
echo "已设置以下环境变量："
echo "CONTEXT7_API_KEY: $(echo $CONTEXT7_API_KEY | cut -c1-10)..."

if [ -n "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN: $(echo $GITHUB_TOKEN | cut -c1-10)..."
else
  echo "GITHUB_TOKEN: 未设置（可选）"
fi

if [ -n "$BRAVE_API_KEY" ]; then
  echo "BRAVE_API_KEY: $(echo $BRAVE_API_KEY | cut -c1-10)..."
else
  echo "BRAVE_API_KEY: 未设置（可选）"
fi

echo ""
echo "提示："
echo "1. 要将这些环境变量永久保存，请添加到 ~/.bashrc 或 ~/.zshrc"
echo "2. 在 Neovim 中测试 Context7: :CodeCompanionChat"
echo "3. 然后输入: @{context7} Get React documentation"