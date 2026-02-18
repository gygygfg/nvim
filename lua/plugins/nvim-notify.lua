-- 安装 nvim-notify 并针对 Mason 优化
return {
  "rcarriga/nvim-notify",
  config = function()
    require("notify").setup({
      stages = "fade_in_slide_out",
      timeout = 3000,
      background_colour = "#000000",
      max_width = 80,
      render = "minimal",

      -- 针对不同来源的消息设置不同样式
      -- 特别是 Mason 相关的消息
    })

    -- 重写 vim.notify 以处理 Mason 消息
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      opts = opts or {}

      -- 识别 Mason 安装消息
      if type(msg) == "string" and msg:find("%[mason.*%]") then
        opts.title = "Mason"
        opts.timeout = 2500 -- 2.5秒后自动消失

        -- 使用底部位置
        opts.position = "bottom_right"
        opts.render = "minimal"

        -- 使用 notify 的异步通知，不阻塞
        require("notify")(msg, level, opts)
        return
      end

      -- 其他消息正常处理
      original_notify(msg, level, opts)
    end
  end
}
