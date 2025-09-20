# iSeeFit Backend API

iSeeFit 的后端 API 服务，支持用户登录、饮食/健身打卡记录、图片处理和个性化推荐功能。

## 功能特性

- 🔐 **用户认证**: JWT 令牌认证，支持用户注册和登录
- 🍎 **饮食记录**: 记录每日饮食，包括卡路里、营养成分分析
- 💪 **健身记录**: 记录运动数据，包括时长、卡路里消耗等
- 📸 **图片处理**: 支持图片上传、压缩和存储
- 🤖 **智能推荐**: 基于用户数据的个性化饮食和运动推荐
- 📊 **数据统计**: 提供日、周、月统计数据
- 🗄️ **MySQL 数据库**: 使用 SQLAlchemy ORM 管理数据

## 技术栈

- **FastAPI**: 现代、快速的 Web 框架
- **SQLAlchemy**: Python SQL 工具包和 ORM
- **MySQL**: 关系型数据库
- **JWT**: JSON Web Token 认证
- **Pillow**: 图片处理
- **Pydantic**: 数据验证

## 快速开始

### 1. 安装依赖

```bash
pip install -r requirements.txt
```

### 2. 配置数据库

确保 MySQL 服务正在运行，然后创建数据库：

```bash
# 设置环境变量
export DB_HOST=localhost
export DB_PORT=3306
export DB_USER=root
export DB_PASSWORD=your_password
export DB_NAME=iseefit

# 或者创建 .env 文件
cp .env.example .env
# 编辑 .env 文件设置你的数据库配置
```

### 3. 创建数据库和表

#### 方法一：使用 Python 脚本（推荐）

```bash
python create_database.py
```

#### 方法二：手动执行 SQL 语句

1. **创建数据库**：
```sql
CREATE DATABASE IF NOT EXISTS iseefit CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE iseefit;
```

2. **创建用户表**：
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    age INT,
    height FLOAT,
    weight FLOAT,
    gender VARCHAR(10),
    activity_level VARCHAR(20),
    goal VARCHAR(20),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_username (username),
    INDEX idx_email (email)
);
```

3. **创建饮食记录表**：
```sql
CREATE TABLE meal_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    meal_type VARCHAR(20) NOT NULL,
    food_name VARCHAR(200) NOT NULL,
    calories FLOAT NOT NULL,
    protein FLOAT DEFAULT 0,
    carbs FLOAT DEFAULT 0,
    fat FLOAT DEFAULT 0,
    portion_size VARCHAR(100),
    image_path VARCHAR(500),
    notes TEXT,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

4. **创建健身记录表**：
```sql
CREATE TABLE workout_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    workout_type VARCHAR(100) NOT NULL,
    duration_minutes INT NOT NULL,
    calories_burned FLOAT NOT NULL,
    intensity VARCHAR(20),
    reps INT,
    sets INT,
    weight_used FLOAT,
    image_path VARCHAR(500),
    notes TEXT,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

5. **创建推荐表**：
```sql
CREATE TABLE recommendations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    recommendation_type VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    is_read BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

6. **插入示例数据**：
```sql
-- 插入示例用户
INSERT INTO users (username, email, hashed_password, full_name, age, height, weight, gender, activity_level, goal) VALUES
('testuser', 'test@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Qz8K2', 'Test User', 25, 170.0, 70.0, 'male', 'moderate', 'maintain'),
('demouser', 'demo@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Qz8K2', 'Demo User', 28, 165.0, 60.0, 'female', 'active', 'lose_weight');

-- 插入示例饮食记录
INSERT INTO meal_records (user_id, meal_type, food_name, calories, protein, carbs, fat, portion_size, notes) VALUES
(1, 'breakfast', 'Oatmeal with Berries', 320, 15, 55, 8, '1 bowl', 'Added blueberries and almonds'),
(1, 'lunch', 'Grilled Chicken Salad', 450, 35, 20, 18, '1 large bowl', 'Mixed greens with olive oil dressing'),
(1, 'dinner', 'Salmon with Vegetables', 520, 42, 25, 22, '1 fillet', 'Steamed broccoli and sweet potato'),
(1, 'snack', 'Greek Yogurt', 150, 12, 8, 5, '1 cup', 'Plain Greek yogurt with honey'),
(2, 'breakfast', 'Avocado Toast', 280, 12, 30, 12, '2 slices', 'Whole grain bread with avocado'),
(2, 'lunch', 'Quinoa Bowl', 380, 18, 45, 12, '1 bowl', 'With chickpeas and vegetables'),
(2, 'dinner', 'Turkey Stir Fry', 420, 35, 30, 15, '1 plate', 'With mixed vegetables and brown rice');

-- 插入示例健身记录
INSERT INTO workout_records (user_id, workout_type, duration_minutes, calories_burned, intensity, reps, sets, weight_used, notes) VALUES
(1, 'Running', 30, 300, 'moderate', NULL, NULL, NULL, 'Morning jog in the park'),
(1, 'Weight Training', 45, 250, 'high', 12, 3, 50.0, 'Chest and back workout'),
(1, 'Yoga', 60, 150, 'low', NULL, NULL, NULL, 'Evening relaxation session'),
(1, 'Swimming', 40, 400, 'moderate', NULL, NULL, NULL, 'Freestyle laps'),
(2, 'HIIT', 25, 350, 'high', NULL, NULL, NULL, 'High intensity interval training'),
(2, 'Pilates', 50, 200, 'moderate', NULL, NULL, NULL, 'Core strengthening session'),
(2, 'Cycling', 35, 280, 'moderate', NULL, NULL, NULL, 'Indoor cycling class');

-- 插入示例推荐
INSERT INTO recommendations (user_id, recommendation_type, title, content, priority) VALUES
(1, 'meal', 'Increase Protein Intake', 'Consider adding more protein-rich foods like eggs, Greek yogurt, or lean meats to your breakfast to support muscle maintenance.', 'medium'),
(1, 'workout', 'Add Cardio Variety', 'Try incorporating different types of cardio exercises like swimming or cycling to improve cardiovascular health and prevent boredom.', 'high'),
(1, 'general', 'Stay Hydrated', 'Remember to drink 8-10 glasses of water daily, especially during and after workouts to maintain proper hydration.', 'low'),
(2, 'meal', 'Control Portion Sizes', 'For weight loss goals, consider measuring your food portions to ensure you are in a calorie deficit while still getting adequate nutrition.', 'high'),
(2, 'workout', 'Increase Workout Frequency', 'Aim for at least 4-5 workout sessions per week to maximize your weight loss results and improve overall fitness.', 'high'),
(2, 'general', 'Track Your Progress', 'Keep a consistent record of your meals and workouts to better understand your patterns and make necessary adjustments.', 'medium');
```

**注意**：示例用户密码为 `password123`，已使用 bcrypt 加密。

这将创建所有必要的数据库表和示例数据。

### 4. 启动服务器

```bash
python start_server.py
```

或者使用 uvicorn 直接启动：

```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### 5. 访问 API 文档

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## API 端点

### 认证相关
- `POST /auth/register` - 用户注册
- `POST /auth/login` - 用户登录
- `GET /auth/me` - 获取当前用户信息

### 饮食记录
- `POST /meals/` - 创建饮食记录
- `GET /meals/` - 获取饮食记录列表
- `GET /meals/today` - 获取今日饮食记录
- `GET /meals/stats/daily` - 获取每日饮食统计
- `GET /meals/stats/weekly` - 获取每周饮食统计
- `PUT /meals/{meal_id}` - 更新饮食记录
- `DELETE /meals/{meal_id}` - 删除饮食记录

### 健身记录
- `POST /workouts/` - 创建健身记录
- `GET /workouts/` - 获取健身记录列表
- `GET /workouts/today` - 获取今日健身记录
- `GET /workouts/stats/daily` - 获取每日健身统计
- `GET /workouts/stats/weekly` - 获取每周健身统计
- `GET /workouts/stats/monthly` - 获取每月健身统计
- `PUT /workouts/{workout_id}` - 更新健身记录
- `DELETE /workouts/{workout_id}` - 删除健身记录

### 推荐系统
- `GET /recommendations/` - 获取推荐列表
- `GET /recommendations/unread` - 获取未读推荐
- `GET /recommendations/stats` - 获取推荐统计
- `POST /recommendations/generate` - 生成新推荐
- `PUT /recommendations/{recommendation_id}/read` - 标记推荐为已读
- `PUT /recommendations/read-all` - 标记所有推荐为已读
- `DELETE /recommendations/{recommendation_id}` - 删除推荐

## 数据库模型

### User (用户)
- 基本信息：用户名、邮箱、密码
- 身体数据：年龄、身高、体重、性别
- 目标设置：活动水平、健身目标

### MealRecord (饮食记录)
- 餐次信息：餐次类型、食物名称
- 营养成分：卡路里、蛋白质、碳水化合物、脂肪
- 其他信息：分量、图片、备注

### WorkoutRecord (健身记录)
- 运动信息：运动类型、时长、强度
- 数据记录：卡路里消耗、组数、次数、重量
- 其他信息：图片、备注

### Recommendation (推荐)
- 推荐内容：类型、标题、内容
- 优先级：低、中、高
- 状态：已读/未读

## 环境变量

```bash
# 数据库配置
DATABASE_URL=mysql+pymysql://root:password@localhost:3306/iseefit
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=password
DB_NAME=iseefit

# JWT 配置
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 文件上传配置
UPLOAD_DIR=uploads
MAX_FILE_SIZE=10485760  # 10MB

# 日志配置
LOG_LEVEL=INFO

# 推荐系统配置
RECOMMENDATION_UPDATE_INTERVAL=24  # 小时
```

## 开发

### 项目结构

```
backend/
├── main.py                 # 主应用文件
├── config.py              # 配置文件
├── init_db.py             # 数据库初始化
├── start_server.py        # 启动脚本
├── requirements.txt       # 依赖列表
├── meal_routes.py         # 饮食记录路由
├── workout_routes.py      # 健身记录路由
├── recommendation_routes.py # 推荐路由
├── recommendation_engine.py # 推荐引擎
└── README.md              # 说明文档
```

### 添加新功能

1. 在相应的路由文件中添加新的端点
2. 在 `main.py` 中定义新的数据库模型（如果需要）
3. 更新 API 文档

### 测试

```bash
# 运行测试
pytest

# 运行特定测试
pytest tests/test_auth.py
```

## 部署

### Docker 部署

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["python", "start_server.py"]
```

### 生产环境配置

1. 设置强密码和安全的 SECRET_KEY
2. 配置 HTTPS
3. 设置适当的 CORS 策略
4. 配置数据库连接池
5. 设置日志轮转
6. 配置监控和告警

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 联系方式

如有问题，请联系开发团队。
