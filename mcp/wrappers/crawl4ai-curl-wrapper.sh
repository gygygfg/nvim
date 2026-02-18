#!/bin/bash
# crawl4ai curl 包装器
# 使用 curl 直接调用 Crawl4AI API

set -e

# Crawl4AI API 地址
CRAWL4AI_API_URL="http://localhost:11235"

# 默认参数值
THRESHOLD="0.4"
THRESHOLD_TYPE="fixed"
CACHE_MODE="bypass"
HEADLESS="true"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    --threshold-type)
      THRESHOLD_TYPE="$2"
      shift 2
      ;;
    --cache-mode)
      CACHE_MODE="$2"
      shift 2
      ;;
    --headless)
      HEADLESS="$2"
      shift 2
      ;;
    *)
      # 忽略未知参数
      shift
      ;;
  esac
done

# 检查 API 是否可用
if ! curl -s --head "${CRAWL4AI_API_URL}" >/dev/null 2>&1; then
  echo "错误: Crawl4AI API 服务未运行在 ${CRAWL4AI_API_URL}" >&2
  echo "请确保 Crawl4AI 服务已启动并监听端口 11235" >&2
  exit 1
fi

# 解析 STDIN 输入（MCP 协议消息）
read -r -d '' INPUT_JSON || true

# 调试：输出接收到的输入
# echo "DEBUG: Received input: $INPUT_JSON" >&2

# 解析 URL 参数
URL=$(echo "$INPUT_JSON" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$URL" ]; then
  echo "错误: 未找到 URL 参数" >&2
  exit 1
fi

# 创建任务 ID
TASK_ID="crawl_$(date +%s%N | md5sum | cut -c1-8)"

# 创建 webhook 回调 URL（使用临时文件接收结果）
RESULT_FILE="/tmp/crawl4ai_result_${TASK_ID}.json"
WEBHOOK_URL="file://${RESULT_FILE}"

# 构建 curl 请求
REQUEST_JSON=$(cat <<EOF
{
  "urls": ["${URL}"],
  "browser_config": {
    "headless": ${HEADLESS}
  },
  "crawler_config": {
    "cache_mode": "${CACHE_MODE}",
    "markdown_generator": {
      "type": "default",
      "content_filter": {
        "type": "pruning",
        "threshold": ${THRESHOLD},
        "threshold_type": "${THRESHOLD_TYPE}"
      }
    }
  },
  "webhook_config": {
    "webhook_url": "${WEBHOOK_URL}",
    "webhook_data_in_payload": true
  }
}
EOF
)

# 发送爬取请求
echo "正在爬取 URL: ${URL}" >&2
RESPONSE=$(curl -s -X POST "${CRAWL4AI_API_URL}/crawl/job" \
  -H "Content-Type: application/json" \
  -d "${REQUEST_JSON}")

# 检查响应
if echo "$RESPONSE" | grep -q "task_id"; then
  TASK_ID_FROM_RESPONSE=$(echo "$RESPONSE" | grep -o '"task_id":"[^"]*"' | cut -d'"' -f4)
  echo "任务已创建: ${TASK_ID_FROM_RESPONSE}" >&2
  
  # 等待任务完成（轮询）
  MAX_WAIT=30
  WAIT_COUNT=0
  while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if [ -f "$RESULT_FILE" ]; then
      break
    fi
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
  done
  
  if [ -f "$RESULT_FILE" ]; then
    # 读取结果文件
    RESULT_CONTENT=$(cat "$RESULT_FILE")
    
    # 提取 fit_markdown
    FIT_MARKDOWN=$(echo "$RESULT_CONTENT" | grep -o '"fit_markdown":"[^"]*"' | cut -d'"' -f4 | sed 's/\\n/\n/g' | sed 's/\\"/"/g')
    
    if [ -n "$FIT_MARKDOWN" ]; then
      # 构建 MCP 响应
      cat <<EOF
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "${FIT_MARKDOWN}"
      }
    ]
  }
}
EOF
    else
      # 如果没有 fit_markdown，返回原始 markdown
      RAW_MARKDOWN=$(echo "$RESULT_CONTENT" | grep -o '"raw_markdown":"[^"]*"' | cut -d'"' -f4 | sed 's/\\n/\n/g' | sed 's/\\"/"/g')
      
      if [ -n "$RAW_MARKDOWN" ]; then
        cat <<EOF
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "${RAW_MARKDOWN}"
      }
    ]
  }
}
EOF
      else
        echo "错误: 无法从响应中提取内容" >&2
        exit 1
      fi
    fi
    
    # 清理临时文件
    rm -f "$RESULT_FILE"
  else
    echo "错误: 任务超时，未收到结果" >&2
    exit 1
  fi
else
  echo "错误: API 请求失败" >&2
  echo "响应: ${RESPONSE}" >&2
  exit 1
fi