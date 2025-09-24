# 体重追踪 API 测试指南

## 前提条件

1. **启动后端服务**：
   ```bash
   cd iSeeFit-py/iseefit
   python run.py
   ```

2. **确保数据库已创建**：
   - 运行 `CREATE TABLE` 语句创建 `weight_records` 表
   - 确保有测试用户数据

## 测试步骤

### 1. 创建测试用户

```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "testpass123",
    "full_name": "Test User",
    "age": 25,
    "height": 170.0,
    "weight": 65.0,
    "gender": "female",
    "activity_level": "moderate",
    "goal": "maintain"
  }'
```

### 2. 用户登录

```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "testpass123"
  }'
```

**保存返回的 `access_token`**

### 3. 测试 BMI 计算

```bash
curl -X POST "http://localhost:8000/weight/bmi" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "weight": 65.5,
    "height": 170.0
  }'
```

**预期响应**：
```json
{
  "bmi": 22.6,
  "category": "normal",
  "description": "正常 (BMI 18.5-24.9)",
  "color": "green"
}
```

### 4. 创建体重记录

```bash
curl -X POST "http://localhost:8000/weight/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "weight": 65.5,
    "height": 170.0,
    "notes": "晨起空腹测量"
  }'
```

**预期响应**：
```json
{
  "id": 1,
  "user_id": 1,
  "weight": 65.5,
  "height": 170.0,
  "bmi": 22.6,
  "notes": "晨起空腹测量",
  "image_path": null,
  "recorded_at": "2025-01-19T10:30:00Z",
  "created_at": "2025-01-19T10:30:00Z",
  "updated_at": "2025-01-19T10:30:00Z"
}
```

### 5. 获取体重历史

```bash
curl -X GET "http://localhost:8000/weight/" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 6. 获取体重统计

```bash
curl -X GET "http://localhost:8000/weight/stats?days=30" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**预期响应**：
```json
{
  "current_weight": 65.5,
  "previous_weight": null,
  "weight_change": 0.0,
  "weight_change_percentage": 0.0,
  "average_weight": 65.5,
  "min_weight": 65.5,
  "max_weight": 65.5,
  "record_count": 1,
  "bmi": 22.6,
  "bmi_category": "normal",
  "period_days": 30
}
```

### 7. 获取体重趋势

```bash
curl -X GET "http://localhost:8000/weight/trend?days=30" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 8. 获取最新体重

```bash
curl -X GET "http://localhost:8000/weight/latest" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### 9. 更新体重记录

```bash
curl -X PUT "http://localhost:8000/weight/1" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "weight": 66.0,
    "notes": "更新后的体重记录"
  }'
```

### 10. 删除体重记录

```bash
curl -X DELETE "http://localhost:8000/weight/1" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## 使用 Postman 测试

1. **导入环境变量**：
   - `base_url`: `http://localhost:8000`
   - `access_token`: 从登录响应中获取

2. **创建请求集合**：
   - 所有请求都使用 `{{base_url}}` 作为基础 URL
   - 需要认证的请求添加 Header: `Authorization: Bearer {{access_token}}`

## 使用 Swagger UI 测试

1. 访问 `http://localhost:8000/docs`
2. 点击 "Authorize" 按钮
3. 输入 `Bearer YOUR_ACCESS_TOKEN`
4. 测试各个接口

## 预期结果

- ✅ 所有接口都应该返回 200 状态码（除了需要认证的接口返回 401）
- ✅ BMI 计算应该准确
- ✅ 体重记录应该正确保存和检索
- ✅ 统计信息应该正确计算
- ✅ 趋势数据应该正确生成

## 常见问题

1. **401 Unauthorized**: 检查 access_token 是否正确
2. **404 Not Found**: 检查 API 路径是否正确
3. **500 Internal Server Error**: 检查数据库连接和表结构
4. **422 Validation Error**: 检查请求数据格式是否正确

