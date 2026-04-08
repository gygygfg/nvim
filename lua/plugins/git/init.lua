-- Git 相关配置（vim pack 格式）
-- 这个文件管理所有与 Git 相关的配置
-- 插件通过 vim pack 系统加载

-- ============================================
-- Git 插件安装定义
-- ============================================

vim.pack.add({
  -- Git 集成
  -- fugitive.vim - Git 集成
  gh("tpope/vim-fugitive"),
  -- diffview.nvim - Git diff 查看
  gh("sindrets/diffview.nvim"),
  -- gitsigns.nvim - Git 状态显示
  gh("lewis6991/gitsigns.nvim"),
})

-- ============================================
-- Git 配置加载
-- ============================================
local function smart_git_error_handler(data, error_type)
  -- 智能 Git 错误处理函数
  if not data or #data == 0 then
    return
  end

  local stderr_text = table.concat(data, "\n")

  -- 过滤掉正常的 Git 信息输出，只显示真正的错误
  local is_normal_git_output = false

  -- 通用的正常 Git 输出模式
  local normal_patterns = {
    "^From ",
    "^ *branch",
    "^ *-> FETCH_HEAD",
    "^Already up%-to%-date",
    "^Fast%-forward",
    "^Updating",
    "^Merge made by",
    "^Press ENTER or type command to continue",
    "^remote: ",
    "^Receiving objects:",
    "^Resolving deltas:",
    "^Unpacking objects:",
    "^Checking connectivity:",
    "^Counting objects:",
    "^Compressing objects:",
    "^Total ",
    "^Delta compression",
    "^Done",
    "^To ",
    "^ *\\[new branch\\]",
    "^ *\\[new tag\\]",
    "^Everything up%-to%-date",
    "^Branch '",
    "^Your branch is up to date",
    "^Writing objects:",
    "^Enumerating objects:",
    "^Pack%-reused:",
    "^Reusing existing pack",
  }

  -- 错误模式：识别真正的错误信息
  local error_patterns = {
    "error: cannot pull with rebase",
    "error: You have unstaged changes",
    "fatal:",
    "error:",
    "conflict",
    "CONFLICT",
    "merge conflict",
    "Automatic merge failed",
  }

  -- 首先检查是否是真正的错误
  local is_error = false
  for _, pattern in ipairs(error_patterns) do
    if stderr_text:match(pattern) then
      is_error = true
      break
    end
  end

  -- 如果是错误，直接显示为错误
  if is_error then
    vim.notify(error_type .. ": " .. stderr_text, vim.log.levels.ERROR)
    return
  end

  -- 检查是否匹配任何正常模式
  for _, pattern in ipairs(normal_patterns) do
    if stderr_text:match(pattern) then
      is_normal_git_output = true
      break
    end
  end

  -- 如果是正常的 Git 输出，显示为 INFO 级别
  if is_normal_git_output then
    vim.notify("Git: " .. stderr_text, vim.log.levels.INFO)
  else
    -- 否则显示为警告（可能是未知的输出）
    vim.notify(error_type .. ": " .. stderr_text, vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  -- 初始化 Git 相关配置
  -- 加载 git commit 模块
  once = true,
  callback = function()
    require("plugins.git.commit").setup()

    -- 加载 fugitive 配置模块
    require("plugins.git.fugitive").setup()

    -- 设置快捷键映射
    -- git 插件 vim-fugitive 专用快捷键
    -- 在 Gstatus 窗口中的快捷键（安装后自动生效）
    -- s: 暂存/取消暂存文件
    -- u: 取消暂存
    -- cc: 提交
    -- ca: 修改提交
    -- ce: 修改提交（不编辑信息）
    vim.keymap.set("n", "<leader>gs", "<cmd>Gstatus<CR>", { desc = "[Git] 状态" })
    vim.keymap.set("n", "<leader>gd", "<cmd>Gdiff<CR>", { desc = "[Git] 差异" })
    vim.keymap.set("n", "<leader>gb", "<cmd>Gblame<CR>", { desc = "[Git] 追溯" })
    vim.keymap.set("n", "<leader>gp", "<cmd>Git push<CR>", { desc = "[Git] 推送" })
    vim.keymap.set("n", "<leader>gl", "<cmd>Git pull<CR>", { desc = "[Git] 拉取" })
    vim.keymap.set("n", "<leader>gw", "<cmd>Gwrite<CR>", { desc = "[Git] 暂存文件" })
    vim.keymap.set("n", "<leader>gr", "<cmd>Gread<CR>", { desc = "[Git] 检出文件" })

    vim.api.nvim_create_user_command("Gitignore", function()
      -- 生成.gitignore文件
      local filetypes = vim.fn.input("输入技术栈 (如 node,python): ")
      if filetypes ~= "" then
        local cmd = string.format("curl -sL https://www.toptal.com/developers/gitignore/api/%s > .gitignore", filetypes)
        vim.fn.system(cmd)
        vim.cmd("edit .gitignore")
        print("Gitignore 文件已生成")
      end
    end, {})

    vim.api.nvim_create_autocmd("BufReadPost", {
      -- 当检测到合并冲突时自动打开 diff 视图
      pattern = "*",
      callback = function()
        if vim.fn.search("^<<<<<<<", "nw") > 0 then
          vim.notify("检测到合并冲突，正在打开 Gdiff...", vim.log.levels.INFO)
          vim.defer_fn(function()
            vim.cmd("Gdiff")
          end, 100)
        end
      end,
    })

    vim.keymap.set("n", "<leader>gbb", function()
      -- 快捷键：快速 blame 并定位问题
      vim.cmd("Gblame")
      -- 自动调整窗口布局
      vim.cmd("wincmd L")
      vim.cmd("vertical resize 40")
    end, { desc = "Git Blame (详细模式)" })

    -- 配置快捷键
    vim.keymap.set("n", "<leader>gdc", function()
      vim.cmd("DiffviewOpen origin/main...HEAD")
    end, { desc = "查看并解决冲突" })

    vim.keymap.set("n", "<leader>gpp", function()
      -- 使用 rebase 方式合并当前分支并推送到远程（静默模式）
      local branch_output = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")

      -- 检查是否是分离头指针状态
      if branch_output == "HEAD" then
        vim.notify("❌ 当前处于分离头指针状态，无法推送", vim.log.levels.ERROR)
        vim.notify("请先使用 <leader>gpf 修复分离头指针状态", vim.log.levels.INFO)
        return
      end

      local branch = branch_output

      -- 检查是否有未提交的更改（包括未暂存和已暂存的）
      local status_cmd = "git status --porcelain"
      local status = vim.fn.system(status_cmd)

      -- 调试：显示状态输出
      -- print("Git status output:", status)

      if status ~= "" then
        -- 解析状态输出，提供更详细的提示
        local lines = vim.split(status, "\n")
        local changes = {}

        for _, line in ipairs(lines) do
          if line ~= "" then
            local status_code = line:sub(1, 2)
            local filename = line:sub(4)

            local status_desc = ""
            if status_code:match("^[MARC]") then
              status_desc = "已暂存: "
            elseif status_code:match("^.[MDARCU?]") then
              status_desc = "未暂存: "
            end

            table.insert(changes, status_desc .. filename)
          end
        end

        local change_count = #changes
        local message = "⚠️  有 " .. change_count .. " 个未提交的更改，请先提交或暂存"

        if change_count <= 3 then
          message = message .. ":\n" .. table.concat(changes, "\n")
        else
          message = message
            .. "（前3个）:\n"
            .. table.concat({ unpack(changes, 1, 3) }, "\n")
            .. "\n... 还有 "
            .. (change_count - 3)
            .. " 个文件"
        end

        vim.notify(message, vim.log.levels.WARN)
        return
      end

      -- 静默模式：不显示开始推送的通知
      -- vim.notify("✓ 分支 " .. branch .. " 正在推送中...", vim.log.levels.INFO)

      vim.fn.jobstart({ "git", "pull", "--rebase", "origin", branch }, {
        -- 使用异步执行避免阻塞界面，添加错误处理
        on_exit = function(_, exit_code)
          if exit_code ~= 0 then
            vim.notify("❌ git pull --rebase 失败，可能有冲突需要解决", vim.log.levels.ERROR)

            -- 检查是否有冲突需要解决
            local conflict_check = vim.fn.system("git diff --name-only --diff-filter=U")
            if conflict_check ~= "" then
              vim.notify("⚠️  检测到合并冲突，请先解决冲突", vim.log.levels.WARN)
              vim.cmd("Gdiff")
            end
            return
          end

          -- 推送前检查是否有需要推送的内容
          -- ahead_check: 本地分支领先于远程分支的提交数（需要推送的提交）
          -- behind_check: 远程分支领先于本地分支的提交数（需要拉取的提交）
          local ahead_check = vim.fn.system("git rev-list --count origin/" .. branch .. "..HEAD 2>/dev/null || echo 0")
          local behind_check = vim.fn.system("git rev-list --count HEAD..origin/" .. branch .. " 2>/dev/null || echo 0")

          if tonumber(ahead_check) == 0 then
            -- 静默模式：不显示没有需要推送的通知
            -- vim.notify("ℹ️  没有需要推送的更改", vim.log.levels.INFO)
            return
          end

          vim.fn.jobstart({ "git", "push", "origin", branch }, {
            on_exit = function(_, push_exit_code)
              if push_exit_code == 0 then
                -- 静默模式：只显示简短的成功通知
                vim.notify("✅ 分支 " .. branch .. " 已推送", vim.log.levels.INFO)
              else
                vim.notify("❌ git push 失败，请检查网络连接或权限", vim.log.levels.ERROR)

                -- 显示推送失败的原因
                vim.fn.jobstart({ "git", "push", "origin", branch, "--verbose" }, {
                  on_stderr = function(_, data)
                    smart_git_error_handler(data, "推送错误")
                  end,
                })
              end
            end,
          })
        end,
        on_stderr = function(_, data)
          smart_git_error_handler(data, "rebase 错误")
        end,
      })
    end, { desc = "使用 rebase 合并并推送当前分支（静默模式）" })

    -- 添加 telescope git_commits 快捷键
    vim.keymap.set("n", "<leader>gh", function()
      -- 硬重置整个项目到指定提交
      require("telescope.builtin").git_commits({
        attach_mappings = function(prompt_bufnr, map)
          map("i", "<CR>", function()
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            if selection then
              vim.ui.input({ prompt = "确认硬重置到 " .. selection.value .. "? (y/N): " }, function(confirm)
                if confirm and confirm:lower() == "y" then
                  vim.cmd("!git reset --hard " .. selection.value)
                  vim.notify("✅ 已硬重置到提交: " .. selection.value, vim.log.levels.INFO)
                else
                  vim.notify("❌ 操作已取消", vim.log.levels.INFO)
                end
              end)
            end
          end)
          return true
        end,
      })
    end, { desc = "硬重置整个项目到指定提交" })

    -- 检查 GitHub 推送状态
    vim.keymap.set("n", "<leader>gps", function()
      local branch_output = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")

      -- 检查是否是分离头指针状态
      if branch_output == "HEAD" then
        vim.notify("⚠️  当前处于分离头指针状态，无法推送", vim.log.levels.WARN)

        -- 显示可用的分支
        local branches = vim.fn.system("git branch --list"):gsub("\n", " ")
        vim.notify("可用分支: " .. branches, vim.log.levels.INFO)

        -- 建议切换到主分支
        vim.notify("建议使用: git checkout main", vim.log.levels.INFO)
        return
      end

      local branch = branch_output

      -- 检查本地和远程的差异
      local cmd = "git log --oneline origin/" .. branch .. "..HEAD 2>/dev/null || echo '无法获取远程分支信息'"
      local local_ahead = vim.fn.system(cmd)

      if local_ahead:match("无法获取远程分支信息") then
        vim.notify("⚠️  无法连接到远程仓库或分支不存在", vim.log.levels.WARN)
        return
      end

      if local_ahead == "" then
        vim.notify("✅ 本地分支与远程分支同步，没有需要推送的提交", vim.log.levels.INFO)
      else
        local count = select(2, local_ahead:gsub("\n", ""))
        vim.notify(
          "📊 本地有 " .. count .. " 个提交需要推送到 GitHub:\n" .. local_ahead,
          vim.log.levels.INFO
        )
      end

      -- 检查最近一次推送状态
      vim.fn.jobstart({ "git", "log", "--oneline", "-1", "--pretty=format:%h %s (%cr)" }, {
        on_exit = function(_, exit_code, data)
          if exit_code == 0 and data and #data > 0 then
            vim.notify("最近提交: " .. data[1], vim.log.levels.INFO)
          end
        end,
      })
    end, { desc = "检查 GitHub 推送状态" })

    -- 修复分离头指针并推送
    vim.keymap.set("n", "<leader>gpf", function()
      local branch_output = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")

      -- 检查是否是分离头指针状态
      if branch_output == "HEAD" then
        vim.notify("🔧 检测到分离头指针状态，正在尝试修复...", vim.log.levels.INFO)

        -- 询问用户要切换到哪个分支
        local target_branch = vim.fn.input("请输入要切换到的分支名 (默认: main): ", "main")
        if target_branch == "" then
          target_branch = "main"
        end

        -- 智能分支检查
        local function check_branch_exists(branch_name)
          local output = vim.fn.system("git show-ref --verify refs/heads/" .. branch_name .. " 2>/dev/null; echo $?")
          -- 只取最后一行作为退出码
          local lines = {}
          for line in output:gmatch("[^\n]+") do
            table.insert(lines, line)
          end
          return lines[#lines] or "128"
        end

        -- 首先检查用户输入的分支
        local branch_exists = check_branch_exists(target_branch)

        -- 如果分支不存在，检查是否是 main/master 别名问题
        local actual_branch = target_branch
        if branch_exists ~= "0" then
          -- 检查另一个常见的主分支名
          local alternative_branch = (target_branch == "main") and "master" or "main"
          local alt_exists = check_branch_exists(alternative_branch)

          if alt_exists == "0" then
            local use_alt = vim.fn.input(
              "分支 "
                .. target_branch
                .. " 不存在，但存在 "
                .. alternative_branch
                .. " 分支，是否切换到 "
                .. alternative_branch
                .. "？(y/n): "
            )
            if use_alt:lower() == "y" then
              actual_branch = alternative_branch
              branch_exists = "0"
            end
          end
        end

        if branch_exists == "0" then
          -- 分支存在，切换到该分支
          vim.notify("正在切换到分支: " .. actual_branch, vim.log.levels.INFO)

          -- 使用 vim.fn.system 同步执行以获取详细错误信息
          local output = vim.fn.system({ "git", "checkout", actual_branch })
          local exit_code = vim.v.shell_error

          if exit_code == 0 then
            vim.notify("✅ 已切换到分支: " .. actual_branch, vim.log.levels.INFO)

            -- 询问是否要提交当前更改
            local status = vim.fn.system("git status --porcelain")
            if status ~= "" then
              local choice = vim.fn.input("有未提交的更改，是否提交？(y/n): ")
              if choice:lower() == "y" then
                -- 使用 git_commit 模块提交
                vim.ui.input({
                  prompt = "提交信息: ",
                  default = "",
                }, function(input)
                  if input and input ~= "" then
                    -- 使用安全的 git commit 函数，启用自动暂存
                    local success, commit_hash_or_error, result =
                      git_commit.safe_git_commit(input, { auto_stage = true })

                    if success then
                      if commit_hash_or_error ~= "" then
                        vim.notify(
                          "✅ 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. input,
                          vim.log.levels.INFO
                        )
                      else
                        vim.notify("✅ 提交成功: " .. input, vim.log.levels.INFO)
                      end
                    else
                      vim.notify("❌ 提交失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
                    end
                  else
                    -- 用户没有输入，使用 AI 生成提交信息
                    vim.notify("正在请求 AI 生成提交信息...", vim.log.levels.INFO, { timeout = 1500 })

                    git_commit.generate_ai_commit_message(function(ai_message)
                      if ai_message then
                        -- 显示 AI 生成的提交信息并询问是否确认
                        vim.ui.input({
                          prompt = "AI 生成的提交信息 (按 Enter 确认，或输入新信息): ",
                          default = ai_message,
                        }, function(final_input)
                          if final_input and final_input ~= "" then
                            -- 使用安全的 git commit 函数，启用自动暂存
                            local success, commit_hash_or_error, result =
                              git_commit.safe_git_commit(final_input, { auto_stage = true })

                            if success then
                              if commit_hash_or_error ~= "" then
                                vim.notify(
                                  "✅ AI 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. final_input,
                                  vim.log.levels.INFO
                                )
                              else
                                vim.notify("✅ AI 提交成功: " .. final_input, vim.log.levels.INFO)
                              end
                            else
                              vim.notify("❌ AI 提交失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
                            end
                          else
                            vim.notify("提交已取消", vim.log.levels.WARN)
                          end
                        end)
                      else
                        vim.notify("AI 生成提交信息失败，请手动输入", vim.log.levels.ERROR)
                      end
                    end, { include_unstaged = true })
                  end
                end)
              end
            end
          else
            -- 显示详细的错误信息
            vim.notify("❌ 无法切换到分支: " .. actual_branch, vim.log.levels.ERROR)
            vim.notify("错误信息: " .. output, vim.log.levels.ERROR)

            -- 检查是否是未提交更改导致的错误
            if
              output:match("Your local changes")
              or output:match("overwritten by checkout")
              or output:match("uncommitted changes")
            then
              vim.notify("🔧 检测到未提交的更改阻止分支切换", vim.log.levels.WARN)

              -- 显示未提交的文件
              local uncommitted_files = vim.fn.system("git status --porcelain")
              if uncommitted_files ~= "" then
                vim.notify("未提交的文件:\n" .. uncommitted_files, vim.log.levels.INFO)
              end

              -- 提供处理选项
              vim.notify("请选择处理方式:", vim.log.levels.INFO)
              print("1. 暂存更改 (git stash) - 保存更改，切换后恢复")
              print("2. 提交更改 - 在当前状态提交")
              print("3. 放弃更改 - 丢弃未提交的更改")
              print("4. 取消 - 不切换分支")

              local choice = vim.fn.input("请输入选项 (1-4): ")

              if choice == "1" then
                -- 暂存更改
                vim.notify("正在暂存更改...", vim.log.levels.INFO)
                local stash_output = vim.fn.system({ "git", "stash" })
                if vim.v.shell_error == 0 then
                  vim.notify("✅ 更改已暂存", vim.log.levels.INFO)

                  -- 重新尝试切换分支
                  vim.notify("重新尝试切换到分支: " .. actual_branch, vim.log.levels.INFO)
                  local retry_output = vim.fn.system({ "git", "checkout", actual_branch })
                  if vim.v.shell_error == 0 then
                    vim.notify("✅ 已切换到分支: " .. actual_branch, vim.log.levels.INFO)

                    -- 询问是否恢复暂存的更改
                    local restore_choice = vim.fn.input("是否恢复暂存的更改？(y/n): ")
                    if restore_choice:lower() == "y" then
                      local pop_output = vim.fn.system({ "git", "stash", "pop" })
                      if vim.v.shell_error == 0 then
                        vim.notify("✅ 已恢复暂存的更改", vim.log.levels.INFO)
                      else
                        vim.notify("❌ 恢复暂存失败: " .. pop_output, vim.log.levels.ERROR)
                      end
                    end
                  else
                    vim.notify("❌ 切换分支失败: " .. retry_output, vim.log.levels.ERROR)
                  end
                else
                  vim.notify("❌ 暂存失败: " .. stash_output, vim.log.levels.ERROR)
                end
              elseif choice == "2" then
                -- 提交更改
                vim.notify("📝 准备提交更改...", vim.log.levels.INFO)

                -- 显示更改内容
                local diff_output = vim.fn.system("git diff --stat")
                if diff_output ~= "" then
                  vim.notify("更改统计:\n" .. diff_output, vim.log.levels.INFO)
                end

                -- 使用 git_commit 模块提交
                vim.ui.input({
                  prompt = "提交信息: ",
                  default = "",
                }, function(input)
                  if input and input ~= "" then
                    -- 使用安全的 git commit 函数，启用自动暂存
                    local success, commit_hash_or_error, result =
                      git_commit.safe_git_commit(input, { auto_stage = true })

                    if success then
                      if commit_hash_or_error ~= "" then
                        vim.notify(
                          "✅ 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. input,
                          vim.log.levels.INFO
                        )

                        -- 提交成功后重新尝试切换分支
                        vim.notify("重新尝试切换到分支: " .. actual_branch, vim.log.levels.INFO)
                        local retry_output = vim.fn.system({ "git", "checkout", actual_branch })
                        if vim.v.shell_error == 0 then
                          vim.notify("✅ 已切换到分支: " .. actual_branch, vim.log.levels.INFO)
                        else
                          vim.notify("❌ 切换分支失败: " .. retry_output, vim.log.levels.ERROR)
                        end
                      else
                        vim.notify("✅ 提交成功: " .. input, vim.log.levels.INFO)
                      end
                    else
                      vim.notify("❌ 提交失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
                    end
                  else
                    -- 用户没有输入，使用 AI 生成提交信息
                    vim.notify("正在请求 AI 生成提交信息...", vim.log.levels.INFO, { timeout = 1500 })

                    git_commit.generate_ai_commit_message(function(ai_message)
                      if ai_message then
                        -- 显示 AI 生成的提交信息并询问是否确认
                        vim.ui.input({
                          prompt = "AI 生成的提交信息 (按 Enter 确认，或输入新信息): ",
                          default = ai_message,
                        }, function(final_input)
                          if final_input and final_input ~= "" then
                            -- 使用安全的 git commit 函数，启用自动暂存
                            local success, commit_hash_or_error, result =
                              git_commit.safe_git_commit(final_input, { auto_stage = true })

                            if success then
                              if commit_hash_or_error ~= "" then
                                vim.notify(
                                  "✅ AI 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. final_input,
                                  vim.log.levels.INFO
                                )

                                -- 提交成功后重新尝试切换分支
                                vim.notify("重新尝试切换到分支: " .. actual_branch, vim.log.levels.INFO)
                                local retry_output = vim.fn.system({ "git", "checkout", actual_branch })
                                if vim.v.shell_error == 0 then
                                  vim.notify("✅ 已切换到分支: " .. actual_branch, vim.log.levels.INFO)
                                else
                                  vim.notify("❌ 切换分支失败: " .. retry_output, vim.log.levels.ERROR)
                                end
                              else
                                vim.notify("✅ AI 提交成功: " .. final_input, vim.log.levels.INFO)
                              end
                            else
                              vim.notify("❌ AI 提交失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
                            end
                          else
                            vim.notify("提交已取消", vim.log.levels.WARN)
                          end
                        end)
                      else
                        vim.notify("AI 生成提交信息失败，请手动输入", vim.log.levels.ERROR)
                      end
                    end, { include_unstaged = true })
                  end
                end)
              elseif choice == "3" then
                -- 放弃更改
                local confirm =
                  vim.fn.input("⚠️  确定要丢弃所有未提交的更改吗？(输入 'yes' 确认): ")
                if confirm:lower() == "yes" then
                  vim.notify("正在丢弃更改...", vim.log.levels.WARN)
                  local reset_output = vim.fn.system({ "git", "checkout", "--", "." })
                  if vim.v.shell_error == 0 then
                    vim.notify("✅ 已丢弃所有未提交的更改", vim.log.levels.INFO)

                    -- 重新尝试切换分支
                    vim.notify("重新尝试切换到分支: " .. actual_branch, vim.log.levels.INFO)
                    local retry_output = vim.fn.system({ "git", "checkout", actual_branch })
                    if vim.v.shell_error == 0 then
                      vim.notify("✅ 已切换到分支: " .. actual_branch, vim.log.levels.INFO)
                    else
                      vim.notify("❌ 切换分支失败: " .. retry_output, vim.log.levels.ERROR)
                    end
                  else
                    vim.notify("❌ 丢弃更改失败: " .. reset_output, vim.log.levels.ERROR)
                  end
                else
                  vim.notify("操作已取消", vim.log.levels.INFO)
                end
              elseif choice == "4" then
                vim.notify("操作已取消", vim.log.levels.INFO)
              else
                vim.notify("无效选项，操作已取消", vim.log.levels.WARN)
              end
            elseif output:match("not found") then
              vim.notify(
                "提示：分支可能不存在，尝试使用 git branch -a 查看所有分支",
                vim.log.levels.INFO
              )
            else
              vim.notify("未知错误，请检查 git 输出", vim.log.levels.ERROR)
            end
          end
        else
          -- 分支不存在，创建新分支
          local create_choice =
            vim.fn.input("分支 " .. actual_branch .. " 不存在，是否创建新分支？(y/n): ")
          if create_choice:lower() == "y" then
            vim.notify("正在创建新分支: " .. actual_branch, vim.log.levels.INFO)

            -- 使用 vim.fn.system 同步执行以获取详细错误信息
            local output = vim.fn.system({ "git", "checkout", "-b", actual_branch })
            local exit_code = vim.v.shell_error

            if exit_code == 0 then
              vim.notify("✅ 已创建并切换到新分支: " .. actual_branch, vim.log.levels.INFO)

              -- 询问是否要提交当前更改
              local status = vim.fn.system("git status --porcelain")
              if status ~= "" then
                local choice = vim.fn.input("有未提交的更改，是否提交？(y/n): ")
                if choice:lower() == "y" then
                  -- 使用 git_commit 模块提交
                  vim.ui.input({
                    prompt = "提交信息: ",
                    default = "",
                  }, function(input)
                    if input and input ~= "" then
                      -- 使用安全的 git commit 函数，启用自动暂存
                      local success, commit_hash_or_error, result =
                        git_commit.safe_git_commit(input, { auto_stage = true })

                      if success then
                        if commit_hash_or_error ~= "" then
                          vim.notify(
                            "✅ 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. input,
                            vim.log.levels.INFO
                          )
                        else
                          vim.notify("✅ 提交成功: " .. input, vim.log.levels.INFO)
                        end
                      else
                        vim.notify("❌ 提交失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
                      end
                    else
                      -- 用户没有输入，使用 AI 生成提交信息
                      vim.notify("正在请求 AI 生成提交信息...", vim.log.levels.INFO, { timeout = 1500 })

                      git_commit.generate_ai_commit_message(function(ai_message)
                        if ai_message then
                          -- 显示 AI 生成的提交信息并询问是否确认
                          vim.ui.input({
                            prompt = "AI 生成的提交信息 (按 Enter 确认，或输入新信息): ",
                            default = ai_message,
                          }, function(final_input)
                            if final_input and final_input ~= "" then
                              -- 使用安全的 git commit 函数，启用自动暂存
                              local success, commit_hash_or_error, result =
                                git_commit.safe_git_commit(final_input, { auto_stage = true })

                              if success then
                                if commit_hash_or_error ~= "" then
                                  vim.notify(
                                    "✅ AI 提交成功: " .. commit_hash_or_error:sub(1, 8) .. " - " .. final_input,
                                    vim.log.levels.INFO
                                  )
                                else
                                  vim.notify("✅ AI 提交成功: " .. final_input, vim.log.levels.INFO)
                                end
                              else
                                vim.notify("❌ AI 提交失败: " .. commit_hash_or_error, vim.log.levels.ERROR)
                              end
                            else
                              vim.notify("提交已取消", vim.log.levels.WARN)
                            end
                          end)
                        else
                          vim.notify("AI 生成提交信息失败，请手动输入", vim.log.levels.ERROR)
                        end
                      end, { include_unstaged = true })
                    end
                  end)
                end
              end
            else
              -- 显示详细的错误信息
              vim.notify("❌ 无法创建新分支: " .. actual_branch, vim.log.levels.ERROR)
              vim.notify("错误信息: " .. output, vim.log.levels.ERROR)

              -- 提供可能的解决方案
              if output:match("already exists") then
                vim.notify(
                  "提示：分支可能已存在，尝试使用 git branch -a 查看所有分支",
                  vim.log.levels.INFO
                )
              elseif output:match("uncommitted changes") then
                vim.notify("提示：有未提交的更改，请先提交或暂存更改", vim.log.levels.INFO)
              end
            end
          end
        end
        return
      end

      -- 如果不是分离头指针，执行正常的推送
      vim.notify("当前已在正常分支上，使用 <leader>gpp 进行推送", vim.log.levels.INFO)
    end, { desc = "修复分离头指针并准备推送" })
  end,
})
