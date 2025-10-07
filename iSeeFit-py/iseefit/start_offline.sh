#!/bin/bash

# 设置离线模式环境变量
export TRANSFORMERS_OFFLINE=1
export HF_HUB_OFFLINE=1
export HF_DATASETS_OFFLINE=1

# 启动应用
echo "Starting iSeeFit backend in offline mode..."
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
