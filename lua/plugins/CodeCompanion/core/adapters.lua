-- CodeCompanion 适配器配置
-- 文件：CodeCompanion/adapters.lua

local M = {}

M.config = {
  http = {
    -- DeepSeek 配置
    deepseek = function()
      return require("codecompanion.adapters").extend("deepseek", {
        name = "deepseek",
        env = {
          api_key = "cmd:echo $DEEPSEEK_API_KEY",
        },
        schema = {
          model = {
            default = "deepseek-chat",
            choices = {
              ["deepseek-chat"] = {
                nice_name = "DeepSeek Chat",
                opts = {
                  max_tokens = 8192,
                },
              },
              ["deepseek-reasoner"] = {
                nice_name = "DeepSeek Reasoner",
                opts = {
                  can_reason = true,
                  max_tokens = 32768,
                },
              },
              ["deepseek-code"] = {
                nice_name = "DeepSeek Coder",
                opts = {
                  max_tokens = 8192,
                },
              },
            },
          },
          temperature = { default = 0.2 },
        },
        opts = {
          timeout = 30000,
          max_retries = 3,
          stream = true,
        },
      })
    end,

    -- Step 配置
    step = function()
      return require("codecompanion.adapters").extend("openai_compatible", {
        name = "step",
        env = {
          url = "https://api.step.com",
          chat_url = "/v1/chat/completions",
          api_key = "cmd:echo $STEP_API_KEY",
        },
        schema = {
          model = {
            default = "step-3.5-flash",
            choices = {
              ["step-3.5-flash"] = {
                nice_name = "Step 3.5 Flash",
              },
            },
          },
          temperature = { default = 0.5 },
        },
      })
    end,
  },

  acp = {
    opts = { show_presets = true },
    opencode = function()
      return require("codecompanion.adapters").extend("opencode", {
        commands = {
          default = { "opencode", "acp" },
        },
      })
    end,
  },
}

return M
