-- MCP Hub 使用示例
-- 文件: examples/mcphub_usage_examples.lua

local M = {}

-- 示例 1: 通用 MCP 访问
M.example_mcp_general = [[
## 通用 MCP 访问 (@mcp)

@{mcp} 当前目录下有哪些文件？

@{mcp} 搜索关于 "neovim configuration" 的文档

@{mcp} 获取 https://example.com 的网页内容
]]

-- 示例 2: 服务器组访问
M.example_server_groups = [[
## 服务器组访问

neovim工具 读取 main.lua 文件

github工具 创建一个 issue

@{fetch} 获取这个网页

@{context7} 搜索关于 "Lua patterns" 的文档
]]

-- 示例 3: 独立工具访问
M.example_individual_tools = [[
## 独立工具访问

@{neovim__read_file} 显示配置文件

@{fetch__fetch} 获取网页内容

@{github__create_issue} 提交 bug 报告

@{crawl4ai__crawl} 爬取 https://news.ycombinator.com 的最新文章

@{context7__search} 搜索关于 "async await" 的文档
]]

-- 示例 4: 自定义工具组访问
M.example_custom_groups = [[
## 自定义工具组访问

@{github_pr_workflow} 从 issue #123 创建 PR

@{web_research} 研究最新的 AI 新闻并保存到文件

@{code_analysis} 分析当前项目的代码结构
]]

-- 示例 5: 资源变量使用
M.example_resource_variables = [[
## 资源变量使用

修复文件中的诊断问题 #{mcp:neovim://diagnostics/buffer}

分析当前缓冲区 #{mcp:neovim:buffer}

查看项目结构 #{mcp:filesystem://current_directory}
]]

-- 示例 6: 斜杠命令使用
M.example_slash_commands = [[
## 斜杠命令使用

/mcp:code_review 检查当前文件的代码质量

/mcp:explain_function 解释这个函数的作用

/mcp:generate_tests 为当前函数生成单元测试

/mcp:refactor_code 重构这段代码
]]

-- 示例 7: 完整工作流
M.example_complete_workflow = [[
## 完整工作流示例

### 场景: 修复 GitHub issue 并创建 PR

1. 读取 issue 内容:
   @{github__get_issue} 获取 issue #456 的详细信息

2. 分析相关代码:
   @{neovim__read_file} 读取相关的源代码文件
   #{mcp:neovim://diagnostics/buffer} 检查代码问题

3. 修复代码:
   @{neovim__edit_file} 修复发现的问题

4. 创建 PR:
   @{github__create_pull_request} 从修复分支创建 PR

5. 通知相关人员:
   @{github__create_issue_comment} 在 issue 中评论 PR 链接
]]

-- 示例 8: 网页研究工作流
M.example_web_research_workflow = [[
## 网页研究工作流

### 场景: 研究最新技术文章并总结

1. 获取网页内容:
   @{crawl4ai__crawl} 爬取 https://techblog.example.com/latest

2. 提取关键信息:
   @{crawl4ai__extract} 提取文章标题、作者、发布日期和主要内容

3. 生成摘要:
   @{crawl4ai__summarize} 生成文章摘要

4. 保存结果:
   @{filesystem__write_file} 将摘要保存到 research_summary.md

5. 分享发现:
   @{github__create_issue} 创建 issue 分享研究发现
]]

-- 示例 9: 代码文档工作流
M.example_code_documentation_workflow = [[
## 代码文档工作流

### 场景: 为项目生成文档

1. 分析代码结构:
   @{filesystem__list_files} 列出项目中的所有文件
   @{neovim__read_file} 读取主要源代码文件

2. 搜索相关文档:
   @{context7__search} 搜索相关技术的官方文档

3. 生成文档:
   /mcp:generate_documentation 为项目生成 README
   /mcp:document_function 为关键函数添加文档注释

4. 验证文档:
   #{mcp:neovim://diagnostics/buffer} 检查文档格式

5. 提交更改:
   @{github__create_or_update_file} 提交文档更新
]]

-- 获取所有示例
function M.get_all_examples()
  return {
    general = M.example_mcp_general,
    server_groups = M.example_server_groups,
    individual_tools = M.example_individual_tools,
    custom_groups = M.example_custom_groups,
    resource_vars = M.example_resource_variables,
    slash_commands = M.example_slash_commands,
    github_workflow = M.example_complete_workflow,
    web_research = M.example_web_research_workflow,
    documentation = M.example_code_documentation_workflow,
  }
end

-- 按类别获取示例
function M.get_examples_by_category(category)
  local examples = M.get_all_examples()
  return examples[category] or "未找到该类别的示例"
end

-- 打印示例菜单
function M.print_example_menu()
  print("=== MCP Hub 使用示例 ===")
  print("1. 通用 MCP 访问 (@mcp)")
  print("2. 服务器组访问")
  print("3. 独立工具访问")
  print("4. 自定义工具组访问")
  print("5. 资源变量使用")
  print("6. 斜杠命令使用")
  print("7. GitHub issue 到 PR 工作流")
  print("8. 网页研究工作流")
  print("9. 代码文档工作流")
  print("输入数字查看对应示例")
end

return M