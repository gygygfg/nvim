# CodeCompanion MCP Integration

A Neovim plugin that integrates **MCP (Model Context Protocol)** servers with [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim), enabling AI-powered coding assistance with access to external tools and services.

## 📋 Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [MCP Servers](#mcp-servers)
- [Usage](#usage)
- [Commands](#commands)
- [Keymaps](#keymaps)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)

---

## ✨ Features

- **MCP Server Integration**: Seamlessly integrates multiple MCP servers with CodeCompanion
- **5 Pre-configured Servers**: Context7, Crawl4AI, Neovim, GitHub, and Filesystem
- **Tool Groups**: Organized tool sets for different workflows (web research, development, etc.)
- **Auto-detection**: Automatically triggers appropriate MCP services based on keywords
- **Status Monitoring**: Built-in commands to check server status and test connections
- **Modular Design**: Clean separation of configuration, adapters, interactions, and display

---

## 📦 Requirements

- **Neovim** >= 0.9.0
- **CodeCompanion.nvim** by olimorris
- **mcphub.nvim** by ravitemer
- **Node.js** (for MCP servers)
- **npm** (for MCP server installation)

### Dependencies (Auto-managed)

- `nvim-lua/plenary.nvim`
- `nvim-treesitter/nvim-treesitter`
- `hrsh7th/nvim-cmp`
- `nvim-telescope/telescope.nvim`
- `stevearc/dressing.nvim`
- `MeanderingProgrammer/render-markdown.nvim`

---

## 🚀 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "olimorris/codecompanion.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp",
    "nvim-telescope/telescope.nvim",
    "stevearc/dressing.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "codecompanion" }
    },
    {
      "ravitemer/mcphub.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      build = "npm install -g mcp-hub@latest",
    },
  },
  opts = function()
    local adapters = require("plugins.CodeCompanion_mcp.adapters")
    local interactions = require("plugins.CodeCompanion_mcp.interactions")
    local display = require("plugins.CodeCompanion_mcp.display")

    return {
      log_level = "DEBUG",
      adapters = adapters.config,
      interactions = interactions.config,
      display = display.config,
      opts = { language = "Chinese" },
    }
  end,
  config = function(_, opts)
    local plugin_dir = debug.getinfo(1, "S").source:match("@?(.*/)")
    if plugin_dir then
      package.path = package.path .. ";" .. plugin_dir .. "codecompanion/?.lua"
      package.path = package.path .. ";" .. plugin_dir .. "codecompanion/_extensions/?.lua"
    end
    require("plugins.CodeCompanion_mcp.config").setup(opts)
  end,
}
```

---

## ⚙️ Configuration

### Environment Variables

Set the following environment variables in your shell configuration:

```bash
# DeepSeek API
export DEEPSEEK_API_KEY="your_deepseek_api_key"

# Step API
export STEP_API_KEY="your_step_api_key"

# GitHub Token (for GitHub MCP server)
export GITHUB_TOKEN="your_github_token"

# Context7 API Key (pre-configured in mcp.lua)
# ctx7sk-be72ace2-0150-4385-acef-8d0596dfff07
```

### Crawl4AI Server

Ensure the Crawl4AI server is running:

```bash
# The server should be running at http://localhost:11235
# API Key: my_local_token_12345
```

---

## 🔌 MCP Servers

| Server | Priority | Description | Status |
|--------|----------|-------------|--------|
| **Context7** | 1 | Code library documentation and examples | ✅ Enabled |
| **Crawl4AI** | 2 | Web crawling and content extraction | ✅ Enabled |
| **Neovim** | 3 | Editor and buffer operations | ✅ Enabled |
| **GitHub** | 4 | Repository and project management | ✅ Enabled |
| **Filesystem** | 5 | File system operations | ✅ Enabled |

### Server Details

#### Context7
- **Purpose**: Fetch latest code library documentation and examples
- **Trigger Keywords**: `documentation`, `docs`, `API`, `library`, `framework`, `npm`, `pip`, `tutorial`, `guide`, `example`, etc.
- **API Key**: Pre-configured

#### Crawl4AI
- **Purpose**: Web crawling and content extraction
- **Trigger Keywords**: `crawl`, `scrape`, `extract`, `webpage`, `website`, `article`, `blog`, `news`, URLs, etc.
- **Base URL**: `http://localhost:11235`

#### Neovim
- **Purpose**: Editor operations (buffer content, window management, etc.)
- **Command**: `npx mcp-neovim-server`

#### GitHub
- **Purpose**: GitHub repository management
- **Command**: `npx @modelcontextprotocol/server-github`
- **Requires**: `GITHUB_TOKEN` environment variable

#### Filesystem
- **Purpose**: File system operations (list, search, read files)
- **Command**: `npx @modelcontextprotocol/server-filesystem`

---

## 💡 Usage

### In CodeCompanion Chat

Use the `@{server}` syntax to invoke specific MCP services:

```text
# Context7 - Get documentation
@{context7} Get React hooks documentation
@{context7} How to use Express.js middleware

# Crawl4AI - Crawl web pages
@{crawl4ai} Crawl https://example.com
@{crawl4ai} Extract content from https://github.com/trending

# GitHub - Repository operations
@{github} List my repositories
@{github} Search for Python projects

# Filesystem - File operations
@{filesystem} List files in current directory
@{filesystem} Search for files containing 'config'

# Neovim - Editor operations
@{neovim} Get current buffer content
@{neovim} List all buffers
```

### Tool Groups

Use predefined tool groups for specific workflows:

```text
# All MCP tools
@{mcp_suite} Find information about Python web frameworks

# Web research (Context7 + Crawl4AI)
@{web_research} Get latest news about AI developments

# Development tools (Context7 + GitHub + Neovim)
@{development} Help me with this coding problem
```

### Auto-trigger Keywords

Simply include these keywords in your query to automatically trigger the appropriate MCP service:

- `use context7` - Force use Context7
- `use crawl4ai` - Force use Crawl4AI
- `use github` - Force use GitHub
- `use mcp` - Use all MCP services

---

## 📜 Commands

| Command | Description |
|---------|-------------|
| `:MCPStatus` | Check status of all MCP servers |
| `:TestMCP` | Test all MCP servers |
| `:MCPHelp` | Display usage guide with floating window |
| `:TestMCPContext7` | Test Context7 server |
| `:TestMCPCrawl4AI` | Test Crawl4AI server |
| `:TestMCPGitHub` | Test GitHub server |
| `:TestMCPFilesystem` | Test Filesystem server |
| `:TestMCPNeovim` | Test Neovim server |

---

## ⌨️ Keymaps

### Chat Window

| Keymap | Description |
|--------|-------------|
| `<C-f>` | Toggle chat window fullscreen |
| `<Esc>` | Exit fullscreen or normal ESC |
| `<leader>mc` | Insert MCP usage examples |

### Global Commands

| Command | Description |
|---------|-------------|
| `:CodeCompanion` or `:cc` | Open CodeCompanion |
| `:CodeCompanionChat` or `:ccc` | Open CodeCompanion Chat |

---

## 🐛 Troubleshooting

### Common Issues

#### 1. MCP Servers Not Starting
```vim
" Check server status
:MCPStatus

" View MCP Hub logs
:edit ~/.local/state/nvim/mcp-hub.log
```

**Solutions:**
- Ensure `~/.config/nvim/mcp/servers.json` exists
- Verify all server command paths are correct
- Check environment variables are set

#### 2. MCP Hub Not Loading
```vim
" Check health
:checkhealth mcphub

" Reinstall if needed
:!npm install -g mcp-hub@latest
```

#### 3. Specific Server Issues
```vim
" Test individual server
:TestMCPContext7
:TestMCPCrawl4AI

" Check CodeCompanion logs
:CodeCompanionLog
```

#### 4. Crawl4AI Connection Failed
Ensure the Crawl4AI server is running:
```bash
# Check if server is running
curl http://localhost:11235/health

# Restart if needed
```

### Debug Mode

Enable debug logging in your configuration:
```lua
log_level = "DEBUG", -- TRACE > DEBUG > INFO > ERROR
```

---

## 📁 Project Structure

```
CodeCompanion_mcp/
├── init.lua                    # Main plugin configuration
├── config.lua                  # Setup and command registration
├── adapters.lua                # AI adapter configurations (DeepSeek, Step)
├── interactions.lua            # Interaction strategies and tool settings
├── display.lua                 # UI display configurations
├── mcp.lua                     # MCP server configurations
├── mcp_integration.lua         # MCP integration module (status, tests, help)
├── README.md                   # This documentation
├── README_MCP_INTEGRATION.md   # Chinese integration guide
├── INTEGRATION_SUMMARY.md      # Integration summary
└── codecompanion/
    └── _extensions/
        └── mcphub.lua          # MCP Hub extension module
```

### Module Responsibilities

| File | Purpose |
|------|---------|
| `init.lua` | Plugin entry point, dependency management |
| `config.lua` | Main setup, keymaps, autocommands |
| `adapters.lua` | AI model adapters (DeepSeek, Step) |
| `interactions.lua` | Tool configurations, system prompts |
| `display.lua` | Window layout, UI preferences |
| `mcp.lua` | MCP server definitions and settings |
| `mcp_integration.lua` | Status checks, testing, help system |
| `mcphub.lua` | CodeCompanion extension for MCP Hub |

---

## 🔧 Development

### Adding New MCP Servers

1. Add server configuration in `mcp.lua`:
```lua
M.servers.my_new_server = {
  enabled = true,
  command = "npx",
  args = {"@mcp/my-new-server"},
  autoApprove = true,
  priority = 6,
  description = "My new MCP server",
}
```

2. Add test function in `mcp_integration.lua`:
```lua
function M.test_my_new_server()
  vim.notify("🧪 Testing My New Server...", vim.log.levels.INFO)
  -- Add test logic
end
```

3. Reload configuration and test:
```vim
:luafile ~/.config/nvim/lua/plugins/CodeCompanion_mcp/init.lua
:TestMCP
```

---

## 📝 License

This project follows the same license as CodeCompanion.nvim.

---

## 🙏 Credits

- [CodeCompanion.nvim](https://github.com/olimorris/codecompanion.nvim) by olimorris
- [MCP Hub](https://github.com/ravitemer/mcphub.nvim) by ravitemer
- [Context7 MCP](https://github.com/upstash/context7-mcp) by Upstash
- [Crawl4AI MCP](https://github.com/unclecode/crawl4ai) by unclecode

---

**Last Updated**: February 16, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
