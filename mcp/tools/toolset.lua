-- 自动生成的 MCP 工具集配置
-- 生成时间: 2026-02-16 12:26:32

return {
  ["filesystem"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "文件系统操作",
  },
  ["filesystem__list_files"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "列出目录中的文件",
  },
  ["filesystem__read_file"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "读取文件内容",
  },
  ["filesystem__write_file"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "写入文件内容",
  },
  ["neovim"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "Neovim 编辑器和缓冲区操作",
  },
  ["neovim__get_buffer"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "获取当前缓冲区内容",
  },
  ["neovim__list_buffers"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "列出所有缓冲区",
  },
  ["neovim__execute_command"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "执行 Neovim 命令",
  },
  ["crawl4ai"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "网页爬取和内容提取",
  },
  ["crawl4ai__crawl_webpage"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "爬取网页内容并提取结构化信息",
  },
  ["crawl4ai__extract_content"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "从网页内容中提取特定信息",
  },
  ["crawl4ai__batch_crawl"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "批量爬取多个网页",
  },
  ["context7"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "获取最新的代码库文档和示例",
  },
  ["context7__resolve_library_id"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "解析库标识符，获取库的详细信息",
  },
  ["context7__get_library_docs"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "获取指定库的文档和代码示例",
  },
  ["context7__search_documentation"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "搜索文档和代码示例",
  },
  ["github"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "GitHub 仓库和项目管理",
  },
  ["github__list_repositories"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "列出用户的仓库",
  },
  ["github__get_repository"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "获取仓库详细信息",
  },
  ["github__create_issue"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "创建 GitHub Issue",
  },
  ["mcp"] = {
    enabled = true,
    opts = {
      require_approval_before = false,
      auto_submit_success = true,
      auto_submit_errors = true,
    },
    desc = "访问所有可用的 MCP 服务器",
  },
}
