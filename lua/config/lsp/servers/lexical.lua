-- lexical 配置（已禁用）
-- 此服务器已被禁用，因为它的命令不存在或不需要

return {
  -- 空的配置，防止服务器被启用
  _disabled = true,
  cmd = {"false"},  -- 使用不存在的命令
  filetypes = {},    -- 不关联任何文件类型
}