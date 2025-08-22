#!/bin/bash

# Vercel构建脚本 - 解决权限问题
set -e

echo "开始Vercel构建..."

# 设置正确的权限
chmod +x node_modules/.bin/*

# 使用npx确保vite命令可以执行
echo "执行构建命令..."
npx vite build

echo "构建完成！"
