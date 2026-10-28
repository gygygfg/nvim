-- 临时自测脚本：不会提交任何东西，仅验证 prompt 构建与输出规范化
local M = dofile("/root/.config/nvim/lua/plugins/git/commit.lua")
local I = M._internal
local repo = "/root/code/NeoAI "
local rev = "18578db"

local diff = vim.fn.system("git -C " .. repo .. " show " .. rev .. " --format=")
local stat = vim.fn.system("git -C " .. repo .. " show " .. rev .. " --format= --stat")
local ns = vim.fn.system("git -C " .. repo .. " show " .. rev .. " --format= --name-status")

local ctx = I.build_change_context({ diff = diff, stat = stat, name_status = ns })
print(("has_code=%s doc_only=%s suggested=%s files=%d"):format(
  tostring(ctx.has_code), tostring(ctx.doc_only), tostring(ctx.suggested_type), #ctx.files))

local prompt = I.build_commit_prompt(ctx)
print("prompt chars =", vim.fn.strchars(prompt))
print("包含 lua 代码 diff:", prompt:find("chat_service.lua", 1, true) ~= nil)
print("包含 docs 的 diff 正文:", prompt:find("diff --git a/docs/en/ui_system.md", 1, true) ~= nil)

print("---- prompt 片段 ----")
print(prompt:sub(1, 700))
print("...")
print(prompt:sub(-700))

print("---- 规范化 ----")
local m1, r1 = I.normalize_commit_message("docs: 更新文档\n\n解释：随便写点", ctx)
print("输入 docs -> ", m1, "need_retry=", tostring(r1))
local m2 = I.force_commit_type(m1, ctx)
print("强制纠正 -> ", m2)
local m3, r3 = I.normalize_commit_message("feat(chat): 新增消息折叠规则与视图对齐", ctx)
print("正常输出 -> ", m3, "need_retry=", tostring(r3))
local m4 = I.normalize_commit_message("更新了 chat 配置说明", ctx)
print("无 type -> ", m4)

print("---- 纯文档场景 ----")
local dctx = I.build_change_context({
  diff = diff,
  stat = " docs/a.md | 5 +++--\n README.md | 3 ++-\n 2 files changed, 6 insertions(+), 2 deletions(-)\n",
  name_status = "M\tdocs/a.md\nM\tREADME.md\n",
})
print("has_code=", tostring(dctx.has_code), "doc_only=", tostring(dctx.doc_only), "suggested=", tostring(dctx.suggested_type))
local dm, dr = I.normalize_commit_message("docs: 补充配置项说明", dctx)
print("docs 在纯文档场景 -> ", dm, "need_retry=", tostring(dr))

print("---- 备用方案 ----")
M._internal.generate_fallback_commit_message(ctx, function(m)
  print("fallback ->", m)
end)
M._internal.generate_fallback_commit_message(dctx, function(m)
  print("fallback(docs) ->", m)
end)
