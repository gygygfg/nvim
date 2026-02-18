#!/bin/bash
echo "=== MCP 配置检查 ==="
echo ""

# 1. 检查配置文件
echo "1. 检查配置文件: servers.json"
if [ -f "servers.json" ]; then
    echo "   ✅ 配置文件存在"
    
    # 检查 JSON 格式
    if python3 -m json.tool servers.json > /dev/null 2>&1; then
        echo "   ✅ JSON 格式正确"
        
        # 检查服务器数量
        SERVER_COUNT=$(python3 -c "import json; data=json.load(open('servers.json')); print(len(data.get('mcpServers', {})))")
        echo "   ✅ 找到 $SERVER_COUNT 个 MCP 服务器配置"
        
        # 列出服务器
        python3 -c "
import json
data = json.load(open('servers.json'))
servers = data.get('mcpServers', {})
for name, config in servers.items():
    print(f'      - {name}')
    print(f'        命令: {config.get(\"command\", \"无\")}')
    if 'args' in config:
        print(f'        参数: {\" \".join(config[\"args\"])}')
"
    else
        echo "   ❌ JSON 格式错误"
    fi
else
    echo "   ❌ 配置文件不存在"
fi

echo ""
echo "2. 检查 nvm-wrapper 脚本"
if [ -f "wrappers/nvm-wrapper.sh" ]; then
    echo "   ✅ wrapper 脚本存在"
    
    if [ -x "wrappers/nvm-wrapper.sh" ]; then
        echo "   ✅ wrapper 脚本有执行权限"
    else
        echo "   ❌ wrapper 脚本没有执行权限"
        echo "      运行: chmod +x wrappers/nvm-wrapper.sh"
    fi
else
    echo "   ❌ wrapper 脚本不存在"
fi

echo ""
echo "3. 检查 Node.js 环境"
if . ~/.nvm/nvm.sh && command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo "   ✅ Node.js 可用: $NODE_VERSION"
else
    echo "   ❌ Node.js 不可用或未安装"
fi

echo ""
echo "4. 检查 MCP 服务器包"
PACKAGES=(
    "mcp-neovim-server"
    "@modelcontextprotocol/server-github" 
    "@modelcontextprotocol/server-filesystem"
    "@upstash/context7-mcp"
)

for pkg in "${PACKAGES[@]}"; do
    if . ~/.nvm/nvm.sh && npm list -g "$pkg" --depth=0 > /dev/null 2>&1; then
        echo "   ✅ $pkg 已安装"
    else
        echo "   ❌ $pkg 未安装"
        echo "      运行: . ~/.nvm/nvm.sh && npm install -g $pkg"
    fi
done

echo ""
echo "5. 检查 crawl4ai 服务器"
CRAWL4AI_PATH="/root/.config/nvim/lua/plugins/mcp-crawl4ai-ts/dist/index.js"
if [ -f "$CRAWL4AI_PATH" ]; then
    echo "   ✅ crawl4ai 服务器文件存在"
else
    echo "   ❌ crawl4ai 服务器文件不存在"
    echo "      路径: $CRAWL4AI_PATH"
fi

echo ""
echo "=== 检查完成 ==="
echo ""
echo "建议:"
echo "1. 确保所有检查都通过 ✅"
echo "2. 重启 Neovim"
echo "3. 运行 :MCPStatus 检查状态"
echo "4. 在聊天中测试: @{context7} Get React documentation"
