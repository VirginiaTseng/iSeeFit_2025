# 商业智能仪表板

这是一个使用 Next.js 和 TypeScript 构建的响应式商业智能仪表板。

## 功能特点

- 📊 **实时KPI监控**: 显示总用户数、交易量、收入和增长率
- 📈 **时间序列图表**: 可视化性能趋势，支持收入、用户数、交易数切换
- 📊 **渠道分析**: 水平柱状图显示各渠道表现
- 🌍 **地理分布**: 显示不同国家的收入和用户分布
- 🎛️ **侧边导航栏**: 可折叠的左侧导航栏
- 📱 **响应式设计**: 适配移动端和桌面端
- 🔄 **模拟实时数据**: 每10秒自动更新数据

## 技术栈

- **框架**: Next.js 14
- **语言**: TypeScript
- **样式**: Tailwind CSS
- **图表库**: Recharts
- **图标**: Lucide React

## 安装和运行

1. 安装依赖：
```bash
npm install
```

2. 运行开发服务器：
```bash
npm run dev
```

3. 打开浏览器访问 [http://localhost:3000](http://localhost:3000)

## 项目结构

```
├── app/
│   ├── layout.tsx      # 应用布局
│   ├── page.tsx        # 主页面
│   └── globals.css     # 全局样式
├── dashboard.tsx       # 仪表板主组件
├── package.json        # 项目依赖
├── tailwind.config.js  # Tailwind配置
├── tsconfig.json       # TypeScript配置
└── next.config.js      # Next.js配置
```

## 主要组件

### KPI卡片
- 显示关键业务指标
- 包含变化趋势和百分比
- 彩色图标和动画效果

### 时间序列图表
- 30天历史数据展示
- 支持收入/用户数/交易数切换
- 交互式工具提示

### 渠道分析图表
- 水平柱状图
- 显示各销售渠道表现
- 彩色编码区分渠道

### 地理分布
- 列表形式显示国家数据
- 饼图可视化收入分布
- 实时数据更新

## 自定义和扩展

### 修改数据源
在 `dashboard.tsx` 中的以下函数中修改数据：
- `generateTimeSeriesData()`: 时间序列数据
- `channelData`: 渠道数据
- `countryData`: 国家数据

### 添加新的KPI
在 `calculateKPIs()` 函数中添加新的指标。

### 自定义样式
修改 `tailwind.config.js` 或在组件中使用自定义CSS类。

## 构建生产版本

```bash
npm run build
npm start
```

## 许可证

MIT License

