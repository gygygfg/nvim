# MCP 工具文档

## 概述
本文档包含所有已配置的 MCP 服务器及其工具的详细信息。

## Filesystem (`filesystem`)

文件系统操作

### 工具列表

#### 服务器工具 (`@filesystem`)
- **描述**: 访问 Filesystem 的所有功能
- **使用方式**: `@{filesystem} [查询内容]`
- **示例**: `@{filesystem} List files`

#### 特定工具

##### `filesystem__list_files`
- **描述**: 列出目录中的文件
- **输入参数**:
  - `recursive`: 是否递归列出
    - 类型: `boolean`
  - `path`: 目录路径
    - 默认值: `.`
    - 类型: `string`
- **使用方式**: `@{filesystem__list_files} [参数]`

##### `filesystem__read_file`
- **描述**: 读取文件内容
- **输入参数**:
  - `path`: 文件路径
    - 类型: `string`
- **使用方式**: `@{filesystem__read_file} [参数]`

##### `filesystem__write_file`
- **描述**: 写入文件内容
- **输入参数**:
  - `content`: 文件内容
    - 类型: `string`
  - `path`: 文件路径
    - 类型: `string`
- **使用方式**: `@{filesystem__write_file} [参数]`

---

## Neovim (`neovim`)

Neovim 编辑器和缓冲区操作

### 工具列表

#### 服务器工具 (`@neovim`)
- **描述**: 访问 Neovim 的所有功能
- **使用方式**: `@{neovim} [查询内容]`
- **示例**: `@{neovim} List files`

#### 特定工具

##### `neovim__get_buffer`
- **描述**: 获取当前缓冲区内容
- **输入参数**:
  - `bufnr`: 缓冲区编号，0表示当前缓冲区
    - 类型: `number`
- **使用方式**: `@{neovim__get_buffer} [参数]`

##### `neovim__list_buffers`
- **描述**: 列出所有缓冲区
- **输入参数**:
- **使用方式**: `@{neovim__list_buffers} [参数]`

##### `neovim__execute_command`
- **描述**: 执行 Neovim 命令
- **输入参数**:
  - `command`: Neovim 命令
    - 类型: `string`
- **使用方式**: `@{neovim__execute_command} [参数]`

---

## Crawl4AI (`crawl4ai`)

网页爬取和内容提取

### 工具列表

#### 服务器工具 (`@crawl4ai`)
- **描述**: 访问 Crawl4AI 的所有功能
- **使用方式**: `@{crawl4ai} [查询内容]`
- **示例**: `@{crawl4ai} Crawl https://example.com`

#### 特定工具

##### `crawl4ai__crawl_webpage`
- **描述**: 爬取网页内容并提取结构化信息
- **输入参数**:
  - `url`: 网页URL，如 'https://example.com', 'https://news.ycombinator.com'
    - 类型: `string`
  - `mode`: 爬取模式：'markdown', 'html', 'text', 'screenshot'
    - 默认值: `markdown`
    - 类型: `string`
  - `extract_rules`: 提取规则，用于结构化提取内容
    - 类型: `object`
- **使用方式**: `@{crawl4ai__crawl_webpage} [参数]`

##### `crawl4ai__extract_content`
- **描述**: 从网页内容中提取特定信息
- **输入参数**:
  - `selector`: CSS选择器或XPath，如 '.article', '//h1', '#main'
    - 类型: `string`
  - `extract_type`: 提取类型：'text', 'html', 'links', 'images'
    - 默认值: `text`
    - 类型: `string`
  - `content`: 网页内容或HTML
    - 类型: `string`
- **使用方式**: `@{crawl4ai__extract_content} [参数]`

##### `crawl4ai__batch_crawl`
- **描述**: 批量爬取多个网页
- **输入参数**:
  - `concurrency`: 并发数
    - 默认值: `3`
    - 类型: `number`
  - `urls`: URL列表
    - 类型: `array`
- **使用方式**: `@{crawl4ai__batch_crawl} [参数]`

---

## Context7 (`context7`)

获取最新的代码库文档和示例

### 工具列表

#### 服务器工具 (`@context7`)
- **描述**: 访问 Context7 的所有功能
- **使用方式**: `@{context7} [查询内容]`
- **示例**: `@{context7} Get React documentation`

#### 特定工具

##### `context7__resolve_library_id`
- **描述**: 解析库标识符，获取库的详细信息
- **输入参数**:
  - `query`: 库名称或标识符，如 'react', 'express', 'django'
    - 类型: `string`
- **使用方式**: `@{context7__resolve_library_id} [参数]`

##### `context7__get_library_docs`
- **描述**: 获取指定库的文档和代码示例
- **输入参数**:
  - `query`: 查询内容，如 'hooks', 'middleware', 'models'
    - 类型: `string`
  - `version`: 库版本，如 'latest', '18.0.0', '4.18.0'
    - 类型: `string`
  - `library_id`: 库ID，可通过 resolve_library_id 获取
    - 类型: `string`
- **使用方式**: `@{context7__get_library_docs} [参数]`

##### `context7__search_documentation`
- **描述**: 搜索文档和代码示例
- **输入参数**:
  - `query`: 搜索查询，如 'React hooks', 'Python async', 'Docker compose'
    - 类型: `string`
- **使用方式**: `@{context7__search_documentation} [参数]`

---

## GitHub (`github`)

GitHub 仓库和项目管理

### 工具列表

#### 服务器工具 (`@github`)
- **描述**: 访问 GitHub 的所有功能
- **使用方式**: `@{github} [查询内容]`
- **示例**: `@{github} List files`

#### 特定工具

##### `github__list_repositories`
- **描述**: 列出用户的仓库
- **输入参数**:
  - `username`: GitHub用户名
    - 类型: `string`
  - `type`: 仓库类型：'all', 'owner', 'member'
    - 默认值: `all`
    - 类型: `string`
- **使用方式**: `@{github__list_repositories} [参数]`

##### `github__get_repository`
- **描述**: 获取仓库详细信息
- **输入参数**:
  - `repo`: 仓库名称
    - 类型: `string`
  - `owner`: 仓库所有者
    - 类型: `string`
- **使用方式**: `@{github__get_repository} [参数]`

##### `github__create_issue`
- **描述**: 创建 GitHub Issue
- **输入参数**:
  - `title`: Issue标题
    - 类型: `string`
  - `owner`: 仓库所有者
    - 类型: `string`
  - `repo`: 仓库名称
    - 类型: `string`
  - `body`: Issue内容
    - 类型: `string`
- **使用方式**: `@{github__create_issue} [参数]`

---

## 使用示例

### Context7 示例
```
@{context7} Get React hooks documentation
@{context7__get_library_docs} {library_id: 'react', version: 'latest', query: 'hooks'}
```

### Crawl4AI 示例
```
@{crawl4ai} Crawl https://news.ycombinator.com
@{crawl4ai__crawl_webpage} {url: 'https://example.com', mode: 'markdown'}
```

### 自动调用
在查询中添加以下关键词自动调用相应服务：
- `use context7`: 强制使用 Context7
- `use crawl4ai`: 强制使用 Crawl4AI
- `use mcp`: 使用所有 MCP 服务
