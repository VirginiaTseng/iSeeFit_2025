# iSeeFit - AI 智能食物识别与卡路里分析应用

## 项目概述

iSeeFit 是一个基于 AI 的 web 应用，通过拍照识别食物并自动计算卡路里和营养成分。应用使用 OpenAI 的 GPT-4 Vision 模型进行食物识别和分析。

## 功能特性

### 1. 图片捕获与上传 ✅
- **R1.1**: 相机接口，支持拍照和文件选择
- **R1.2**: 预览确认界面，包含重拍和确认选项  
- **R1.3**: 图片上传到后端 AI 端点，显示加载状态

### 2. AI 识别与营养分析
- 使用 OpenAI GPT-4 Vision 模型分析食物图片
- 识别食物成分和营养成分
- 计算总卡路里和健康评分
- 提供详细的成分分析

## 技术栈

### 前端
- React 18 + TypeScript
- Vite (构建工具)
- Axios (HTTP 客户端)
- CSS3 (样式)

### 后端
- Node.js + Express
- TypeScript
- OpenAI API
- Multer (文件上传)
- CORS (跨域支持)

## 项目结构

```
iSeeFit/
├── iSeeFit-frontend/          # React 前端应用
│   ├── src/
│   │   ├── components/        # React 组件
│   │   │   ├── CameraCapture.tsx    # 相机捕获组件
│   │   │   ├── CameraCapture.css
│   │   │   ├── ImagePreview.tsx     # 图片预览组件
│   │   │   └── ImagePreview.css
│   │   ├── services/          # API 服务
│   │   │   └── apiService.ts
│   │   ├── App.tsx           # 主应用组件
│   │   └── App.css
│   └── package.json
├── iSeeFit-backend/           # Node.js 后端 API
│   ├── src/
│   │   ├── services/
│   │   │   └── openaiService.ts     # OpenAI 服务
│   │   └── index.ts          # 主服务器文件
│   ├── uploads/              # 图片上传目录
│   └── package.json
└── README.md
```

## 快速开始

### 1. 环境准备

确保已安装：
- Node.js (推荐 v18+)
- npm 或 yarn

### 2. 后端设置

```bash
cd iSeeFit-backend

# 安装依赖
npm install

# 创建环境配置文件
cp .env.example .env

# 编辑 .env 文件，添加你的 OpenAI API Key
# OPENAI_API_KEY=your_actual_api_key_here

# 启动后端服务
npm run dev
```

后端服务将在 http://localhost:3001 运行

### 3. 前端设置

```bash
cd iSeeFit-frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

前端应用将在 http://localhost:5173 运行

## API 接口

### POST /api/recognize
上传图片进行食物识别

**请求:**
- Content-Type: multipart/form-data
- Body: image (文件)

**响应:**
```json
{
  "title": "食物名称",
  "ingredients": [
    {
      "name": "成分名称",
      "description": "成分描述",
      "caloriesPerGram": 4.2,
      "totalGrams": 150,
      "totalCalories": 630
    }
  ],
  "totalCalories": 630,
  "healthScore": 7
}
```

### GET /api/health
健康检查端点

**响应:**
```json
{
  "status": "OK",
  "message": "iSeeFit Backend is running",
  "timestamp": "2025-01-03 13:21:51"
}
```

## 使用说明

1. **启动相机**: 点击"启动相机"按钮，允许浏览器访问摄像头
2. **拍照**: 对准食物，点击"拍照"按钮
3. **预览确认**: 查看拍摄的图片，选择"重拍"或"确认分析"
4. **AI 分析**: 系统将图片发送到 OpenAI 进行分析
5. **查看结果**: 查看详细的营养成分和卡路里分析

## 开发说明

### 调试日志
所有组件都包含详细的调试日志，便于开发和调试：
- 相机操作日志
- API 调用日志
- 错误处理日志

### 错误处理
- 相机权限错误处理
- 文件上传错误处理
- API 调用错误处理
- 网络连接错误处理

## 注意事项

1. 需要有效的 OpenAI API Key
2. 需要 HTTPS 环境才能使用相机功能（生产环境）
3. 图片文件大小限制为 10MB
4. 支持常见图片格式 (JPEG, PNG, WebP 等)

## 下一步开发

- [ ] 历史记录功能
- [ ] 用户账户系统
- [ ] 数据持久化
- [ ] 移动端优化
- [ ] 离线功能
