#!/bin/bash
# nvim_with_nvm.sh
# 使用 NVM 环境启动 Neovim

# 加载 NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 设置 Node 版本（如果存在 .nvmrc）
if [ -f ".nvmrc" ]; then
    nvm use
elif [ -f "$HOME/.nvmrc" ]; then
    nvm use
else
    # 使用默认版本
    nvm use default 2>/dev/null || nvm use node 2>/dev/null || true
fi

# 获取当前 Node 路径并添加到 PATH
NODE_BIN_DIR="$(dirname "$(which node 2>/dev/null)")"
if [ -n "$NODE_BIN_DIR" ]; then
    export PATH="$NODE_BIN_DIR:$PATH"
    echo "Node.js environment loaded: $(node --version 2>/dev/null || echo 'Unknown')"
else
    echo "Warning: Node.js not found via NVM"
fi

# 启动 Neovim，传递所有参数
exec nvim "$@"