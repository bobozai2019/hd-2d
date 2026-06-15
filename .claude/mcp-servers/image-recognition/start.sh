#!/bin/bash
# 启动图片识别 MCP Server
export MIMO_API_KEY="tp-c6hm8afg2p8m4eetdnkbsxivhcg95q3j0id0vm57p3q5yjxn"
export MIMO_BASE_URL="https://token-plan-cn.xiaomimimo.com/v1"
export MIMO_MODEL="mimo-v2.5"
python "$(dirname "$0")/server.py"
