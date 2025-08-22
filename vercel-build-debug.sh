#!/bin/bash
set -e

echo "=== 构建环境信息 ==="
echo "Node.js版本: $(node --version)"
echo "npm版本: $(npm --version)"
echo "当前目录: $(pwd)"
echo "目录内容:"
ls -la

echo "=== 安装依赖 ==="
npm install

echo "=== 检查依赖 ==="
npm list --depth=0

echo "=== 开始构建 ==="
npm run build

echo "=== 构建完成 ==="
echo "dist目录内容:"
ls -la dist/

echo "构建成功！"
