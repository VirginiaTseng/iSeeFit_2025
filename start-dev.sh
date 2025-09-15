#!/bin/bash

# iSeeFit 开发环境启动脚本
echo "🍎 启动 iSeeFit 开发环境..."

# 检查 Node.js 版本
echo "检查 Node.js 版本..."
node --version

# 启动后端服务
echo "启动后端服务..."
cd iSeeFit-backend
npm run dev &
BACKEND_PID=$!

# 等待后端启动
sleep 3

# 启动前端服务
echo "启动前端服务..."
cd ../iSeeFit-frontend
npm run dev &
FRONTEND_PID=$!

echo "✅ 服务启动完成！"
echo "📱 前端地址: http://localhost:5173"
echo "🔧 后端地址: http://localhost:3001"
echo ""
echo "按 Ctrl+C 停止所有服务"

# 等待用户中断
wait

# 清理进程
echo "正在停止服务..."
kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
echo "服务已停止"
