#!/bin/bash
# 拦截 Read 工具对图片文件的读取，强制使用 MCP image-recognition 服务
# Hook 类型: PreToolUse，matcher: Read

input=$(cat)

# 从 JSON 输入中提取 file_path
file_path=$(echo "$input" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"$//')

if [ -z "$file_path" ]; then
  exit 0
fi

# 检查文件扩展名是否为图片格式
ext="${file_path##*.}"
ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

case "$ext" in
  png|jpg|jpeg|gif|webp|bmp|svg|ico|tga)
    cat <<'EOF'
{"decision":"block","reason":"禁止使用 Read 工具读取图片文件。请改用 MCP 服务: mcp__image-recognition__image_recognize(image=\"<图片路径>\", prompt=\"描述图片内容\")"}
EOF
    ;;
esac
