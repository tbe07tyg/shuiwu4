#!/bin/bash
set -e

echo "开始Vercel构建..."

# 确保有执行权限
chmod +x node_modules/.bin/vite

# 安装依赖
npm ci

# 构建项目
npm run build

echo "构建完成！"
