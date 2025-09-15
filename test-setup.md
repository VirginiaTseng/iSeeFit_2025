# iSeeFit 测试设置指南

## 快速测试步骤

### 1. 环境配置

**后端环境变量设置:**
```bash
cd iSeeFit-backend
cp .env.example .env
# 编辑 .env 文件，添加你的 OpenAI API Key
```

**前端环境变量设置:**
```bash
cd iSeeFit-frontend
# 创建 .env.local 文件
echo "VITE_API_URL=http://localhost:3001" > .env.local
```

### 2. 启动服务

**方法一：使用启动脚本**
```bash
./start-dev.sh
```

**方法二：分别启动**
```bash
# 终端1 - 后端
cd iSeeFit-backend
npm run dev

# 终端2 - 前端  
cd iSeeFit-frontend
npm run dev
```

### 3. 测试功能

1. 打开浏览器访问 http://localhost:5173
2. 点击"启动相机"按钮
3. 允许浏览器访问摄像头
4. 对准食物拍照
5. 在预览页面点击"确认分析"
6. 查看 AI 分析结果

### 4. 测试文件上传

1. 点击"选择图片"按钮
2. 选择一张食物图片
3. 在预览页面点击"确认分析"
4. 查看 AI 分析结果

## 预期结果

- ✅ 相机功能正常工作
- ✅ 图片预览界面显示正确
- ✅ 图片上传到后端成功
- ✅ AI 分析返回营养成分数据
- ✅ 结果页面显示卡路里和成分信息

## 故障排除

### 相机无法启动
- 确保使用 HTTPS 或 localhost
- 检查浏览器权限设置
- 尝试刷新页面

### API 调用失败
- 检查后端服务是否运行 (http://localhost:3001/api/health)
- 确认 OpenAI API Key 已正确设置
- 查看浏览器控制台错误信息

### 图片上传失败
- 检查图片文件大小 (< 10MB)
- 确认图片格式支持 (JPEG, PNG, WebP)
- 查看网络连接状态
