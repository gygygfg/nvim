# 拼写纠正测试

这是一个测试文件，用于验证自动拼写纠正功能。

## 测试拼写错误的单词

1. 输入一个拼写错误的英文单词，比如 "helo"（应该是 "hello"）
2. 将光标放在这个单词上（或单词内）
3. 按 Tab 键
4. 应该会自动纠正为 "hello"

## 其他测试用例

- "recieve" → "receive"
- "seperate" → "separate"
- "definately" → "definitely"
- "occured" → "occurred"
- "accomodate" → "accommodate"

## 注意事项

- 这个功能只在特定文件类型中启用（如 Markdown、文本文件等）
- 在代码文件中会自动禁用，避免干扰
- 如果自动纠正失败，会显示拼写建议菜单供选择