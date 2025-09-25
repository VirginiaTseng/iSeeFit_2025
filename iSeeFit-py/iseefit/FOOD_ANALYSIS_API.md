# 食物分析API文档

## 概述

食物分析API为iOS应用提供食物图片识别和营养分析功能。该API集成了OpenAI Vision模型和Food-101分类器作为后备方案，能够识别食物并计算营养成分。

## 功能特性

- 🍽️ **智能食物识别**: 使用OpenAI Vision模型识别最多3种食物
- 📊 **营养分析**: 自动计算热量、蛋白质、碳水化合物和脂肪含量
- 🔄 **后备方案**: 当OpenAI不可用时，自动切换到Food-101分类器
- 📱 **iOS友好**: 专为iOS应用设计的JSON响应格式
- 🛡️ **错误处理**: 完善的错误处理和日志记录

## API端点

### 1. 食物分析

**POST** `/api/food/analyze`

分析上传的食物图片并返回营养信息。

#### 请求参数

- `image` (file, required): 食物图片文件
- `use_ai_portions` (boolean, optional): 是否使用AI估算份量，默认true
- `manual_override` (string, optional): 手动指定的食物名称
- `portion_slider` (float, optional): 手动份量（克），默认250.0

#### 响应格式

```json
{
  "timestamp": "2025-01-25T02:19:44.568278Z",
  "mode": "openai_generative",
  "per_item": [
    {
      "Food (detected)": "shrimp",
      "Portion (g)": 150.0,
      "Confidence": 0.8,
      "Calories (kcal)": 300.0,
      "Protein (g)": 9.0,
      "Carbs (g)": 37.5,
      "Fat (g)": 10.5,
      "Source": "built_in"
    }
  ],
  "totals": {
    "Portion (g)": 150.0,
    "Calories (kcal)": 300.0,
    "Protein (g)": 9.0,
    "Carbs (g)": 37.5,
    "Fat (g)": 10.5
  },
  "notes": "检测到虾类食物，建议搭配蔬菜食用"
}
```

#### 错误响应

```json
{
  "error": "无法在图片中检测到食物",
  "debug": "OpenAI调用失败: API key无效"
}
```

### 2. 健康检查

**GET** `/api/food/health`

检查服务状态。

#### 响应格式

```json
{
  "status": "healthy",
  "service": "food_analysis"
}
```

### 3. 配置信息

**GET** `/api/food/config`

获取服务配置信息。

#### 响应格式

```json
{
  "openai_enabled": true,
  "model_name": "gpt-4o-mini",
  "fallback_classifier": "available"
}
```

## 环境配置

### 必需的环境变量

在 `.env` 文件中设置以下变量：

```bash
# OpenAI配置
OPENAI_API_KEY=your_openai_api_key_here

# 调试模式（可选）
DEBUG=0  # 设置为1启用调试模式
```

### 依赖安装

```bash
pip install -r requirements.txt
```

主要依赖包括：
- `openai>=1.40.0`: OpenAI API客户端
- `transformers>=4.30.0`: Hugging Face transformers
- `torch>=2.0.0`: PyTorch深度学习框架
- `torchvision>=0.15.0`: 计算机视觉工具
- `pandas>=1.5.0`: 数据处理
- `Pillow>=9.0.0`: 图像处理

## 使用方法

### 1. 启动服务器

```bash
cd iseefit
python run.py
```

服务器将在 `http://localhost:8000` 启动。

### 2. 测试API

使用提供的测试脚本：

```bash
python test_food_api.py
```

### 3. iOS集成示例

```swift
// Swift代码示例
func analyzeFood(image: UIImage) {
    let url = URL(string: "http://your-server:8000/api/food/analyze")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    
    // 添加图片数据
    if let imageData = image.jpegData(compressionQuality: 0.8) {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"food.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
    }
    
    // 添加其他参数
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"use_ai_portions\"\r\n\r\n".data(using: .utf8)!)
    body.append("true\r\n".data(using: .utf8)!)
    
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = body
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            do {
                let result = try JSONDecoder().decode(FoodAnalysisResult.self, from: data)
                DispatchQueue.main.async {
                    // 处理结果
                    self.handleAnalysisResult(result)
                }
            } catch {
                print("解析错误: \(error)")
            }
        }
    }.resume()
}
```

## 支持的食物类型

API支持识别以下类型的食物：

### 水果
- 苹果、香蕉、橙子等

### 主食/菜品
- 白米饭、炒饭、面条、意大利面
- 披萨、汉堡、薯条、炸鸡
- 甜甜圈、冰淇淋、三明治、煎饼、华夫饼

### 亚洲美食
- 拉面、寿司、饺子、越南粉

### 蛋白质/沙拉/汤
- 牛排、沙拉、鸡肉沙拉、汤

### 常见菜品
- 鸡肉、烤鸡、土豆、烤土豆、豌豆、胡萝卜

### 海鲜
- 虾、鱼、三文鱼

### 蔬菜
- 生菜、番茄、西兰花

## 注意事项

1. **API密钥**: 确保设置有效的OpenAI API密钥以获得最佳识别效果
2. **图片质量**: 上传清晰、光线充足的食物图片以获得更好的识别结果
3. **网络连接**: OpenAI服务需要网络连接，离线时将使用Food-101分类器
4. **响应时间**: AI分析可能需要几秒钟时间，建议设置适当的超时时间
5. **数据准确性**: 营养数据为估算值，仅供参考，不应用于医疗目的

## 故障排除

### 常见问题

1. **OpenAI API错误**
   - 检查API密钥是否正确设置
   - 确认网络连接正常
   - 检查API配额是否充足

2. **图片处理失败**
   - 确保上传的是有效的图片文件
   - 检查图片大小是否过大
   - 尝试使用JPEG或PNG格式

3. **分类器加载失败**
   - 确保已安装所有必需的依赖
   - 检查网络连接以下载模型
   - 查看服务器日志获取详细错误信息

### 调试模式

设置环境变量 `DEBUG=1` 启用调试模式，将返回详细的调试信息。

## 更新日志

- **v1.0.0**: 初始版本，支持OpenAI Vision和Food-101分类器
- 集成到iSeeFit后端API
- 支持iOS应用调用
- 完善的错误处理和日志记录
