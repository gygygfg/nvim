-- Godot 引擎场景与项目操作工具模块
-- 提供 Godot 项目的场景节点获取、添加、修改、删除等常用功能
-- 支持解析 .tscn 场景文件、.tres 资源文件以及 project.godot 项目配置文件
-- 所有工具使用回调模式异步执行，不阻塞主线程
-- 工具函数签名：func(args, on_success, on_error)
local M = {}

local resolve_path = require("NeoAI.tools.builtin.tool_helpers").resolve_path

-- ============================================================================
-- 内部辅助函数
-- ============================================================================

--- 异步读取文件内容（回调模式）
--- 使用 vim.uv 异步 I/O，不阻塞主线程
--- @param filepath string 文件路径
--- @param on_success function(string) 成功回调，返回文件内容
--- @param on_error function(string) 失败回调
local function read_file_async(filepath, on_success, on_error)
  local abs_path = vim.fn.fnamemodify(filepath, ":p")
  vim.uv.fs_open(abs_path, "r", 438, function(open_err, fd)
    if open_err or not fd then
      if on_error then
        on_error("无法读取文件: " .. (open_err or "未知错误"))
      end
      return
    end
    vim.uv.fs_fstat(fd, function(stat_err, stat)
      if stat_err or not stat then
        vim.uv.fs_close(fd)
        if on_error then
          on_error("无法读取文件: " .. (stat_err or "无法获取文件信息"))
        end
        return
      end
      vim.uv.fs_read(fd, stat.size, 0, function(read_err, data)
        vim.uv.fs_close(fd)
        if read_err or not data then
          if on_error then
            on_error("无法读取文件: " .. (read_err or "未知错误"))
          end
          return
        end
        if on_success then
          on_success(data)
        end
      end)
    end)
  end)
end

--- 异步写入文件内容（回调模式）
--- @param filepath string 文件路径
--- @param content string 要写入的内容
--- @param on_success function 成功回调
--- @param on_error function(string) 失败回调
local function write_file_async(filepath, content, on_success, on_error)
  local abs_path = vim.fn.fnamemodify(filepath, ":p")
  vim.uv.fs_open(abs_path, "w", 438, function(open_err, fd)
    if open_err or not fd then
      if on_error then
        on_error("无法写入文件: " .. (open_err or "未知错误"))
      end
      return
    end
    vim.uv.fs_write(fd, content, 0, function(write_err)
      vim.uv.fs_close(fd)
      if write_err then
        if on_error then
          on_error("写入文件失败: " .. (write_err or "未知错误"))
        end
        return
      end
      if on_success then
        on_success({ filepath = abs_path, success = true })
      end
    end)
  end)
end

--- 解析 Godot 格式的键值对字符串
--- 例如: name="Player" type="CharacterBody2D" parent="."
--- @param str string 键值对字符串
--- @return table 解析后的键值对表
local function parse_godot_key_value_pairs(str)
  local result = {}
  if not str then return result end

  -- 匹配 key = value 模式，value 可以是 "..." 或 无引号字符串
  for k, v in str:gmatch('([%w_]+)%s*=%s*"([^"]*)"') do
    result[k] = v
  end
  -- 匹配无引号的值（如数字、布尔等）
  for k, v in str:gmatch('([%w_]+)%s*=%s*([%w_%.]+)') do
    if not result[k] then
      result[k] = v
    end
  end
  return result
end

--- 解析 Godot 属性值（将字符串转为 Lua 类型）
--- @param value string 原始值字符串
--- @return any 解析后的值
local function parse_godot_value(value)
  if not value then return nil end
  value = vim.trim(value)

  -- 布尔值
  if value == "true" then return true end
  if value == "false" then return false end

  -- 数字
  local num = tonumber(value)
  if num then return num end

  -- 空值
  if value == "null" or value == "Nil" then return nil end

  -- 引号字符串
  local quoted = value:match('^"(.+)"$')
  if quoted then return quoted end

  -- 资源引用 ExtResource("id") / SubResource("id")
  local ext_res = value:match('^ExtResource%("(%w+)"%)$')
  if ext_res then return { type = "ExtResource", id = ext_res } end

  local sub_res = value:match('^SubResource%("(%w+)"%)$')
  if sub_res then return { type = "SubResource", id = sub_res } end

  -- 内置类型如 Vector2(x, y), Color(r, g, b, a) 等
  -- 保留原始字符串表示，不做深度解析
  return value
end

--- 将 Lua 值转为 Godot 属性值字符串
--- @param value any Lua 值
--- @return string Godot 格式的字符串
local function serialize_godot_value(value)
  if value == nil then return "null" end
  if type(value) == "boolean" then return value and "true" or "false" end
  if type(value) == "number" then return tostring(value) end
  if type(value) == "string" then
    -- 如果已经是 Godot 内置类型表达式，不加引号
    if value:match("^[A-Z]%w*%(") then
      return value
    end
    return '"' .. value .. '"'
  end
  if type(value) == "table" then
    if value.type == "ExtResource" then
      return 'ExtResource("' .. (value.id or "") .. '")'
    end
    if value.type == "SubResource" then
      return 'SubResource("' .. (value.id or "") .. '")'
    end
    -- 普通 table 转为 Godot 字典格式
    return tostring(value)
  end
  return tostring(value)
end

--- 将 tscn 文件内容解析为结构化节点树
--- .tscn 文件格式示例：
---   [gd_scene load_steps=2 format=3 uid="uid://..."]
---   [ext_resource type="Script" path="res://player.gd" id="1"]
---   [node name="Player" type="CharacterBody2D" parent="."]
---   script = ExtResource("1")
---   position = Vector2(100, 200)
---   [node name="Sprite2D" type="Sprite2D" parent="Player"]
---   ...
--- @param content string .tscn 文件内容
--- @return table 结构化场景数据
local function parse_tscn_content(content)
  if not content or content == "" then
    return { sections = {}, nodes = {} }
  end

  local lines = vim.split(content, "\n", { plain = true })
  local result = {
    headers = {},      -- 头部定义（gd_scene, ext_resource, sub_resource）
    nodes = {},         -- 节点列表（含节点名、类型、父节点、属性等）
    node_tree = {},     -- 树形结构的节点层次
  }

  local current_node = nil
  local node_stack = {}  -- 用于构建树形结构
  local node_by_path = {} -- 按路径索引节点

  for _, line in ipairs(lines) do
    -- 跳过空行和注释
    local trimmed = vim.trim(line or "")
    if trimmed == "" or trimmed:match("^;") then
      goto continue
    end

    -- 解析头部定义行 [gd_scene ...], [ext_resource ...], [sub_resource ...]
    local header_match = trimmed:match("^%[(gd_scene .+)%]$")
      or trimmed:match("^%[(ext_resource .+)%]$")
      or trimmed:match("^%[(sub_resource .+)%]$")
    if header_match then
      -- 先保存上一个节点的属性
      if current_node then
        table.insert(result.nodes, current_node)
        current_node = nil
      end
      local header_type = trimmed:match("^%[(%w+)")
      local header_attrs = parse_godot_key_value_pairs(header_match)
      table.insert(result.headers, {
        type = header_type,
        attributes = header_attrs,
        raw_line = trimmed,
      })
      goto continue
    end

    -- 解析节点定义行 [node ...]
    local node_match = trimmed:match("^%[(node .+)%]$")
    if node_match then
      -- 保存上一个节点
      if current_node then
        table.insert(result.nodes, current_node)
      end
      local node_attrs = parse_godot_key_value_pairs(node_match)
      current_node = {
        name = node_attrs.name,
        node_type = node_attrs.type,
        parent = node_attrs.parent or ".",
        instance = node_attrs.instance,  -- 实例化场景的路径
        groups = node_attrs.groups,
        properties = {},
        children = {},
        raw_start_line = trimmed,
      }
      -- 如果父节点是 "."，表示根节点
      if current_node.parent == "." or not current_node.parent then
        current_node.parent = nil
      end
      goto continue
    end

    -- 如果是节点属性行（在 [node ...] 之后）
    if current_node then
      -- 跳过空行和注释
      local prop_match = trimmed:match("^([%w_]+)%s*=%s*(.+)$")
      if prop_match then
        local key, value = prop_match:match("^([%w_]+)%s*=%s*(.+)$")
        if key and value then
          current_node.properties[key] = parse_godot_value(value)
        end
      end
    end

    ::continue::
  end

  -- 保存最后一个节点
  if current_node then
    table.insert(result.nodes, current_node)
  end

  -- 构建树形结构
  local root_nodes = {}
  local node_map = {}

  -- 先建立所有节点的映射（按名称）
  for _, node in ipairs(result.nodes) do
    local node_copy = vim.deepcopy(node)
    node_copy.children = {}
    node_map[node_copy.name] = node_copy
  end

  -- 建立父子关系
  for _, node in ipairs(result.nodes) do
    local parent_name = node.parent
    if parent_name and node_map[parent_name] then
      if not node_map[parent_name].children then
        node_map[parent_name].children = {}
      end
      table.insert(node_map[parent_name].children, node_map[node.name])
    else
      table.insert(root_nodes, node_map[node.name])
    end
  end

  result.node_tree = root_nodes
  result.node_count = #result.nodes

  return result
end

--- 序列化节点为 tscn 格式文本行
--- @param node table 节点定义
--- @return string tscn 格式的 [node ...] 行
local function serialize_node_header(node)
  local parts = { "[node" }
  table.insert(parts, 'name="' .. (node.name or "Unknown") .. '"')
  table.insert(parts, 'type="' .. (node.node_type or "Node") .. '"')
  if node.parent then
    table.insert(parts, 'parent="' .. node.parent .. '"')
  end
  if node.instance then
    table.insert(parts, 'instance="' .. node.instance .. '"')
  end
  if node.groups then
    table.insert(parts, 'groups="' .. node.groups .. '"')
  end
  return table.concat(parts, " ") .. "]"
end

--- 查找项目根目录（从起始路径向上查找 project.godot）
--- @param start_path string 起始路径
--- @param on_success function(string) 成功回调，返回项目根目录
--- @param on_error function(string) 失败回调
local function find_project_root(start_path, on_success, on_error)
  local current = vim.fn.fnamemodify(start_path, ":p:h")
  local max_depth = 10
  local depth = 0

  while current and depth < max_depth do
    local project_file = current .. "/project.godot"
    local ok = vim.fn.filereadable(project_file)
    if ok == 1 then
      if on_success then on_success(current) end
      return
    end
    local parent = vim.fn.fnamemodify(current, ":h")
    if parent == current then break end  -- 已到根目录
    current = parent
    depth = depth + 1
  end

  if on_error then
    on_error("未找到 Godot 项目文件（project.godot），请确保在 Godot 项目目录中操作")
  end
end

-- ============================================================================
-- 工具函数
-- ============================================================================

--- 列出 Godot 项目中的场景文件
--- @param args { path: string }
--- @param on_success function
--- @param on_error function
M.list_scenes = function(args, on_success, on_error)
  if not args then
    if on_error then on_error("参数不能为空") end
    return
  end

  local project_path = args.path and resolve_path(args.path) or vim.fn.getcwd()

  find_project_root(project_path, function(root_path)
    local results = {}
    local scan_dir

    scan_dir = function(dir, depth, max_depth)
      if depth > max_depth then return end
      local handle = vim.uv.fs_scandir(dir)
      if not handle then return end
      while true do
        local name, type = vim.uv.fs_scandir_next(handle)
        if not name then break end
        local full_path = dir .. "/" .. name
        if type == "directory" then
          if name ~= "." and name ~= ".." and name ~= ".godot" and name ~= "addons" then
            scan_dir(full_path, depth + 1, max_depth)
          end
        elseif type == "file" then
          if name:match("%.tscn$") or name:match("%.tres$") or name:match("%.res$") then
            table.insert(results, {
              name = name,
              path = full_path,
              rel_path = full_path:sub(#root_path + 2),
              type = name:match("%.(%w+)$"),
            })
          end
        end
      end
    end

    scan_dir(root_path, 0, 5)

    if on_success then
      on_success({
        project = root_path,
        count = #results,
        files = results,
      })
    end
  end, on_error)
end

--- 获取场景文件的节点列表
--- @param args { filepath: string }
--- @param on_success function
--- @param on_error function
M.get_scene_nodes = function(args, on_success, on_error)
  if not args or not args.filepath then
    if on_error then on_error("请指定场景文件路径 (filepath)") end
    return
  end

  local filepath = resolve_path(args.filepath)
  local abs_path = vim.fn.fnamemodify(filepath, ":p")

  read_file_async(abs_path, function(content)
    local parsed = parse_tscn_content(content)
    if on_success then
      on_success({
        filepath = abs_path,
        node_count = parsed.node_count or #parsed.nodes,
        nodes = parsed.nodes,
        node_tree = parsed.node_tree,
        headers = parsed.headers,
      })
    end
  end, on_error)
end

--- 获取场景中指定节点的详细信息
--- @param args { filepath: string, name?: string, path?: string, index?: number }
--- @param on_success function
--- @param on_error function
M.get_scene_node = function(args, on_success, on_error)
  if not args or not args.filepath then
    if on_error then on_error("请指定场景文件路径 (filepath)") end
    return
  end

  local filepath = resolve_path(args.filepath)
  local node_name = args.name
  local node_path = args.path
  local node_index = args.index

  if not node_name and not node_path and node_index == nil then
    if on_error then on_error("请指定节点名称 (name)、路径 (path) 或索引 (index)") end
    return
  end

  local abs_path = vim.fn.fnamemodify(filepath, ":p")

  read_file_async(abs_path, function(content)
    local parsed = parse_tscn_content(content)
    local found_node = nil

    if node_index ~= nil then
      found_node = parsed.nodes[node_index + 1]
    elseif node_name then
      for _, node in ipairs(parsed.nodes) do
        if node.name == node_name then
          found_node = node
          break
        end
      end
    elseif node_path then
      local parts = vim.split(node_path, "/", { plain = true })
      local current = parsed.node_tree
      for _, part in ipairs(parts) do
        local matched = false
        for _, node in ipairs(current) do
          if node.name == part then
            current = node.children or {}
            matched = true
            found_node = node
            break
          end
        end
        if not matched then
          found_node = nil
          break
        end
      end
    end

    if found_node then
      if on_success then on_success(found_node) end
    else
      if on_error then on_error("未找到指定节点") end
    end
  end, on_error)
end

--- 在场景中添加新节点
--- @param args { filepath: string, name: string, node_type: string, parent?: string, properties?: table, instance?: string, groups?: string }
--- @param on_success function
--- @param on_error function
M.add_scene_node = function(args, on_success, on_error)
  if not args or not args.filepath then
    if on_error then on_error("请指定场景文件路径 (filepath)") end
    return
  end
  if not args.name then
    if on_error then on_error("请指定节点名称 (name)") end
    return
  end
  if not args.node_type then
    if on_error then on_error("请指定节点类型 (node_type)") end
    return
  end

  local filepath = resolve_path(args.filepath)
  local new_node = {
    name = args.name,
    node_type = args.node_type,
    parent = args.parent,
    instance = args.instance,
    groups = args.groups,
    properties = args.properties or {},
  }

  local abs_path = vim.fn.fnamemodify(filepath, ":p")

  read_file_async(abs_path, function(content)
    local lines = vim.split(content, "\n", { plain = true })
    local insert_line = #lines + 1

    -- 查找插入位置：如果有父节点，在父节点后插入
    if new_node.parent then
      for i, line in ipairs(lines) do
        local node_match = line:match('^%[node name="([^"]+)"')
        if node_match and node_match == new_node.parent then
          insert_line = i + 1
          -- 找到父节点的所有子节点区域末尾
          local parent_indent = 0
          for j = i + 1, #lines do
            local next_node = lines[j]:match("^%[node ")
            if next_node then
              -- 检查是否是父节点的子节点
              local parent_attr = lines[j]:match('parent="([^"]+)"')
              if parent_attr and parent_attr == new_node.parent then
                insert_line = j + 1
              else
                break
              end
            end
          end
          break
        end
      end
    end

    -- 构建新节点的文本
    local node_header = serialize_node_header(new_node)
    local new_lines = { node_header }
    for k, v in pairs(new_node.properties) do
      table.insert(new_lines, k .. " = " .. serialize_godot_value(v))
    end

    -- 插入新行
    local result_lines = {}
    for i = 1, insert_line - 1 do
      table.insert(result_lines, lines[i])
    end
    for _, nl in ipairs(new_lines) do
      table.insert(result_lines, nl)
    end
    for i = insert_line, #lines do
      table.insert(result_lines, lines[i])
    end

    local new_content = table.concat(result_lines, "\n")
    write_file_async(abs_path, new_content, function(res)
      if on_success then
        on_success({
          filepath = abs_path,
          node = new_node,
          success = true,
        })
      end
    end, on_error)
  end, on_error)
end

--- 修改场景节点的属性
--- @param args { filepath: string, name: string, properties: table, merge?: boolean }
--- @param on_success function
--- @param on_error function
M.set_node_properties = function(args, on_success, on_error)
  if not args or not args.filepath then
    if on_error then on_error("请指定场景文件路径 (filepath)") end
    return
  end
  if not args.name then
    if on_error then on_error("请指定节点名称 (name)") end
    return
  end
  if not args.properties or type(args.properties) ~= "table" then
    if on_error then on_error("请指定要设置的属性 (properties)") end
    return
  end

  local filepath = resolve_path(args.filepath)
  local target_name = args.name
  local new_properties = args.properties
  local merge = args.merge

  if merge == nil then merge = true end

  local abs_path = vim.fn.fnamemodify(filepath, ":p")

  read_file_async(abs_path, function(content)
    local parsed = parse_tscn_content(content)
    local lines = vim.split(content, "\n", { plain = true })
    local found_node_line = nil
    local found_node = nil

    -- 查找目标节点
    for i, node in ipairs(parsed.nodes) do
      if node.name == target_name then
        found_node = node
        -- 在原始内容中找到该节点的行号
        for j, line in ipairs(lines) do
          local node_match = line:match('^%[node name="([^"]+)"')
          if node_match and node_match == target_name then
            found_node_line = j
            break
          end
        end
        break
      end
    end

    if not found_node or not found_node_line then
      if on_error then on_error("未找到节点: " .. target_name) end
      return
    end

    -- 更新属性
    if merge then
      for k, v in pairs(new_properties) do
        found_node.properties[k] = v
      end
    else
      found_node.properties = vim.deepcopy(new_properties)
    end

    -- 重建文件内容
    local result_lines = {}
    local in_target_node = false
    local past_properties = false

    for i, line in ipairs(lines) do
      local node_match = line:match('^%[node name="([^"]+)"')
      if node_match and node_match == target_name then
        in_target_node = true
        past_properties = false
        -- 写入节点头
        table.insert(result_lines, serialize_node_header(found_node))
        -- 写入属性
        for k, v in pairs(found_node.properties) do
          table.insert(result_lines, k .. " = " .. serialize_godot_value(v))
        end
        past_properties = true
      elseif line:match("^%[node ") then
        -- 其他节点，直接保留
        table.insert(result_lines, line)
        in_target_node = false
      elseif in_target_node and not past_properties then
        -- 跳过目标节点原有的属性行
        -- 但保留空行和注释
        if line:match("^%s*$") or line:match("^%s*;") then
          table.insert(result_lines, line)
        end
        -- 其他属性行被跳过（已被新属性替代）
      else
        table.insert(result_lines, line)
      end
    end

    local new_content = table.concat(result_lines, "\n")
    write_file_async(abs_path, new_content, function(res)
      if on_success then
        on_success({
          filepath = abs_path,
          node = target_name,
          properties = found_node.properties,
          success = true,
        })
      end
    end, on_error)
  end, on_error)
end

--- 删除场景中的节点
--- @param args { filepath: string, name: string, children?: boolean }
--- @param on_success function
--- @param on_error function
M.remove_scene_node = function(args, on_success, on_error)
  if not args or not args.filepath then
    if on_error then on_error("请指定场景文件路径 (filepath)") end
    return
  end
  if not args.name then
    if on_error then on_error("请指定要删除的节点名称 (name)") end
    return
  end

  local filepath = resolve_path(args.filepath)
  local target_name = args.name
  local remove_children = args.children

  if remove_children == nil then
    remove_children = true
  end

  local abs_path = vim.fn.fnamemodify(filepath, ":p")

  read_file_async(abs_path, function(content)
    local parsed = parse_tscn_content(content)
    local lines = vim.split(content, "\n", { plain = true })
    local lines_to_remove = {}

    -- 查找目标节点及其子节点（如需）
    for i, node in ipairs(parsed.nodes) do
      if node.name == target_name then
        -- 找到节点在文件中的行
        for j, line in ipairs(lines) do
          local node_match = line:match('^%[node name="([^"]+)"')
          if node_match and node_match == target_name then
            table.insert(lines_to_remove, j)
            -- 收集该节点后面直到下一个节点的所有行
            for k = j + 1, #lines do
              if lines[k]:match("^%[node ") then
                break
              end
              table.insert(lines_to_remove, k)
            end
          end
        end

        -- 如果需要删除子节点
        if remove_children then
          for _, other_node in ipairs(parsed.nodes) do
            if other_node.parent == target_name then
              for j, line in ipairs(lines) do
                local node_match = line:match('^%[node name="([^"]+)"')
                if node_match and node_match == other_node.name then
                  table.insert(lines_to_remove, j)
                  for k = j + 1, #lines do
                    if lines[k]:match("^%[node ") then
                      break
                    end
                    table.insert(lines_to_remove, k)
                  end
                end
              end
            end
          end
        end
        break
      end
    end

    if #lines_to_remove == 0 then
      if on_error then on_error("未找到节点: " .. target_name) end
      return
    end

    -- 去重并排序
    local seen = {}
    local sorted = {}
    for _, l in ipairs(lines_to_remove) do
      if not seen[l] then
        seen[l] = true
        table.insert(sorted, l)
      end
    end
    table.sort(sorted, function(a, b) return a > b end)

    -- 从后往前删除行
    local result_lines = {}
    for i, line in ipairs(lines) do
      if not seen[i] then
        table.insert(result_lines, line)
      end
    end

    local new_content = table.concat(result_lines, "\n")
    write_file_async(abs_path, new_content, function(res)
      if on_success then
        on_success({
          filepath = abs_path,
          removed_node = target_name,
          removed_lines = #lines_to_remove,
          success = true,
        })
      end
    end, on_error)
  end, on_error)
end

--- 搜索场景中的节点
--- @param args { filepath: string, node_type?: string, name?: string, property?: string, groups?: string, has_script?: boolean, recursive?: boolean }
--- @param on_success function
--- @param on_error function
M.search_scene_nodes = function(args, on_success, on_error)
  if not args or not args.filepath then
    if on_error then on_error("请指定场景文件路径 (filepath)") end
    return
  end

  local filepath = resolve_path(args.filepath)
  local search_type = args.node_type
  local search_name = args.name
  local search_prop = args.property
  local search_groups = args.groups
  local has_script = args.has_script
  local recursive = args.recursive

  if not search_type and not search_name and not search_prop and not search_groups and has_script == nil then
    if on_error then on_error("请指定至少一个搜索条件") end
    return
  end

  if recursive == nil then recursive = true end

  local abs_path = vim.fn.fnamemodify(filepath, ":p")

  read_file_async(abs_path, function(content)
    local parsed = parse_tscn_content(content)
    local matched = {}

    for _, node in ipairs(parsed.nodes) do
      local match = true

      if search_type and node.node_type ~= search_type then
        match = false
      end
      if search_name and node.name ~= search_name then
        match = false
      end
      if search_prop then
        local prop_found = false
        for k, v in pairs(node.properties) do
          if k == search_prop or tostring(k):match(search_prop) then
            prop_found = true
            break
          end
        end
        if not prop_found then match = false end
      end
      if search_groups and node.groups ~= search_groups then
        match = false
      end
      if has_script ~= nil then
        local has_script_prop = node.properties and node.properties.script ~= nil
        if has_script and not has_script_prop then
          match = false
        elseif not has_script and has_script_prop then
          match = false
        end
      end

      if match then
        table.insert(matched, node)
      end
    end

    if on_success then
      on_success({
        filepath = abs_path,
        total_nodes = #parsed.nodes,
        matched_count = #matched,
        nodes = matched,
      })
    end
  end, on_error)
end

--- 获取项目场景树（所有场景文件的概览）
--- @param args { path?: string, max_depth?: number }
--- @param on_success function
--- @param on_error function
M.project_scene_tree = function(args, on_success, on_error)
  if not args then
    if on_error then on_error("参数不能为空") end
    return
  end

  local project_path = args.path and resolve_path(args.path) or vim.fn.getcwd()

  find_project_root(project_path, function(root_path)
    local max_depth = args.max_depth or 3
    local files = {}
    local scan_dir

    scan_dir = function(dir, depth, max_depth)
      if depth > max_depth then return end
      local handle = vim.uv.fs_scandir(dir)
      if not handle then return end
      while true do
        local name, type = vim.uv.fs_scandir_next(handle)
        if not name then break end
        local full_path = dir .. "/" .. name
        if type == "directory" then
          if name ~= "." and name ~= ".." and name ~= ".godot" then
            scan_dir(full_path, depth + 1, max_depth)
          end
        elseif type == "file" then
          local ext = name:match("%.(%w+)$")
          if ext == "tscn" or ext == "tres" or ext == "res" or ext == "gd" then
            table.insert(files, {
              name = name,
              path = full_path,
              rel_path = full_path:sub(#root_path + 2),
              type = ext == "tscn" and "scene" or (ext == "gd" and "script" or "resource"),
            })
          end
        end
      end
    end

    scan_dir(root_path, 0, max_depth)

    local grouped = { scenes = {}, scripts = {}, resources = {} }
    for _, f in ipairs(files) do
      if f.type == "scene" then
        table.insert(grouped.scenes, f)
      elseif f.type == "script" then
        table.insert(grouped.scripts, f)
      else
        table.insert(grouped.resources, f)
      end
    end

    local result = {
      project = root_path,
      total_files = #files,
      scenes = grouped.scenes,
      scripts = grouped.scripts,
      resources = grouped.resources,
    }

    if on_success then on_success(result) end
  end, on_error)
end

--- 查看场景文件的原始内容
--- @param args { filepath: string, properties?: boolean }
--- @param on_success function
--- @param on_error function
M.view_scene_file = function(args, on_success, on_error)
  if not args or not args.filepath then
    if on_error then on_error("请指定场景文件路径 (filepath)") end
    return
  end

  local filepath = resolve_path(args.filepath)
  local show_properties = args.properties

  local abs_path = vim.fn.fnamemodify(filepath, ":p")

  read_file_async(abs_path, function(content)
    local parsed = parse_tscn_content(content)
    local lines = vim.split(content, "\n", { plain = true })
    local result = {
      filepath = abs_path,
      headers = parsed.headers,
      nodes = parsed.nodes,
      node_tree = parsed.node_tree,
      raw_lines = lines,
      line_count = #lines,
    }

    if on_success then on_success(result) end
  end, on_error)
end

-- ============================================================================
-- 工具注册：供 NeoAI 工具系统调用
-- ============================================================================

--- 返回所有 Godot 工具定义列表
--- @return table[] 工具定义列表，每项包含 name, func, description, parameters, category, async
function M.get_tools()
  return {
    {
      name = "list_scenes",
      func = M.list_scenes,
      description = "列出 Godot 项目中的场景文件（.tscn, .tres, .res），支持指定搜索路径",
      parameters = {
        type = "object",
        properties = {
          path = {
            type = "string",
            description = "项目路径（可选，默认当前工作目录）",
          },
        },
      },
      category = "godot",
      async = true,
    },
    {
      name = "get_scene_nodes",
      func = M.get_scene_nodes,
      description = "获取场景文件的节点列表，返回节点层级结构",
      parameters = {
        type = "object",
        properties = {
          filepath = {
            type = "string",
            description = "场景文件路径（必填）",
          },
        },
        required = { "filepath" },
      },
      category = "godot",
      async = true,
    },
    {
      name = "get_scene_node",
      func = M.get_scene_node,
      description = "获取场景中指定节点的详细信息，支持按名称、路径或索引查找",
      parameters = {
        type = "object",
        properties = {
          filepath = {
            type = "string",
            description = "场景文件路径（必填）",
          },
          name = {
            type = "string",
            description = "节点名称（与 path、index 三选一）",
          },
          path = {
            type = "string",
            description = "节点路径，如 'root/child/grandchild'（与 name、index 三选一）",
          },
          index = {
            type = "number",
            description = "节点索引（从0开始，与 name、path 三选一）",
          },
        },
        required = { "filepath" },
      },
      category = "godot",
      async = true,
    },
    {
      name = "add_scene_node",
      func = M.add_scene_node,
      description = "在场景中添加新节点",
      parameters = {
        type = "object",
        properties = {
          filepath = {
            type = "string",
            description = "场景文件路径（必填）",
          },
          name = {
            type = "string",
            description = "节点名称（必填）",
          },
          node_type = {
            type = "string",
            description = "节点类型，如 Node2D、Sprite2D、Button 等（必填）",
          },
          parent = {
            type = "string",
            description = "父节点名称（可选，默认添加到根节点）",
          },
          properties = {
            type = "object",
            description = "节点属性键值对（可选）",
          },
          instance = {
            type = "string",
            description = "实例化场景路径（可选）",
          },
          groups = {
            type = "string",
            description = "节点组（可选，逗号分隔）",
          },
        },
        required = { "filepath", "name", "node_type" },
      },
      category = "godot",
      async = true,
    },
    {
      name = "set_node_properties",
      func = M.set_node_properties,
      description = "修改场景中已有节点的属性",
      parameters = {
        type = "object",
        properties = {
          filepath = {
            type = "string",
            description = "场景文件路径（必填）",
          },
          name = {
            type = "string",
            description = "节点名称（必填）",
          },
          properties = {
            type = "object",
            description = "要修改的属性键值对（必填）",
          },
          merge = {
            type = "boolean",
            description = "是否合并已有属性（true=合并，false=覆盖，默认 true）",
          },
        },
        required = { "filepath", "name", "properties" },
      },
      category = "godot",
      async = true,
    },
    {
      name = "remove_scene_node",
      func = M.remove_scene_node,
      description = "从场景中删除指定节点",
      parameters = {
        type = "object",
        properties = {
          filepath = {
            type = "string",
            description = "场景文件路径（必填）",
          },
          name = {
            type = "string",
            description = "要删除的节点名称（必填）",
          },
        },
        required = { "filepath", "name" },
      },
      category = "godot",
      async = true,
    },
    {
      name = "search_scene_nodes",
      func = M.search_scene_nodes,
      description = "在场景中搜索节点，支持按名称、类型、属性值模糊匹配",
      parameters = {
        type = "object",
        properties = {
          filepath = {
            type = "string",
            description = "场景文件路径（必填）",
          },
          name = {
            type = "string",
            description = "按名称搜索（可选）",
          },
          node_type = {
            type = "string",
            description = "按节点类型搜索（可选，如 Sprite2D）",
          },
          property = {
            type = "string",
            description = "按属性名搜索（可选）",
          },
          value = {
            type = "string",
            description = "按属性值搜索（可选，支持通配符）",
          },
          max_results = {
            type = "number",
            description = "最大返回数量（可选，默认50）",
          },
        },
        required = { "filepath" },
      },
      category = "godot",
      async = true,
    },
    {
      name = "project_scene_tree",
      func = M.project_scene_tree,
      description = "列出 Godot 项目的完整文件结构，包括场景、脚本和资源文件",
      parameters = {
        type = "object",
        properties = {
          path = {
            type = "string",
            description = "项目路径（可选，默认当前工作目录）",
          },
          max_depth = {
            type = "number",
            description = "最大扫描深度（可选，默认3）",
          },
        },
      },
      category = "godot",
      async = true,
    },
    {
      name = "view_scene_file",
      func = M.view_scene_file,
      description = "查看场景文件的原始内容，包括头部信息、节点列表和层级结构",
      parameters = {
        type = "object",
        properties = {
          filepath = {
            type = "string",
            description = "场景文件路径（必填）",
          },
          properties = {
            type = "boolean",
            description = "是否包含节点属性详情（可选，默认 false）",
          },
        },
        required = { "filepath" },
      },
      category = "godot",
      async = true,
    },
  }
end

return M
