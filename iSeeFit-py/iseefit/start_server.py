#!/usr/bin/env python3
"""
启动 iSeeFit 后端服务器
"""

import uvicorn
import os
import sys
from pathlib import Path

# 添加当前目录到 Python 路径
current_dir = Path(__file__).parent
sys.path.append(str(current_dir))

def main():
    """启动服务器"""
    # 检查环境变量
    if not os.getenv("SECRET_KEY") or os.getenv("SECRET_KEY") == "your-secret-key-here-change-in-production":
        print("WARNING: Please set a secure SECRET_KEY in your environment variables!")
        print("Example: export SECRET_KEY='your-very-secure-secret-key-here'")
    
    # 服务器配置
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    reload = os.getenv("RELOAD", "true").lower() == "true"
    
    print(f"Starting iSeeFit Backend API server...")
    print(f"Host: {host}")
    print(f"Port: {port}")
    print(f"Reload: {reload}")
    print(f"API Documentation: http://{host}:{port}/docs")
    print(f"ReDoc Documentation: http://{host}:{port}/redoc")
    
    # 启动服务器
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=reload,
        log_level="info"
    )

if __name__ == "__main__":
    main()
