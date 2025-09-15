'use client'

import React, { useState, useEffect } from 'react'
import { 
  LineChart, 
  Line, 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts'
import { 
  Users, 
  CreditCard, 
  DollarSign, 
  TrendingUp,
  Home,
  BarChart3,
  Users as UsersIcon,
  Settings,
  Bell,
  Search,
  Calendar,
  Globe,
  ArrowUpRight,
  ArrowDownRight
} from 'lucide-react'

// 类型定义
interface KPIData {
  title: string
  value: string
  change: number
  icon: React.ReactNode
  color: string
}

interface TimeSeriesData {
  date: string
  revenue: number
  users: number
  transactions: number
}

interface ChannelData {
  channel: string
  performance: number
  color: string
}

interface CountryData {
  country: string
  revenue: number
  users: number
  lat: number
  lng: number
}

// 模拟数据生成
const generateTimeSeriesData = (): TimeSeriesData[] => {
  const data: TimeSeriesData[] = []
  const now = new Date()
  
  for (let i = 29; i >= 0; i--) {
    const date = new Date(now)
    date.setDate(date.getDate() - i)
    
    data.push({
      date: date.toISOString().split('T')[0],
      revenue: Math.floor(Math.random() * 50000) + 20000,
      users: Math.floor(Math.random() * 1000) + 500,
      transactions: Math.floor(Math.random() * 500) + 200
    })
  }
  
  return data
}

const channelData: ChannelData[] = [
  { channel: '线上商城', performance: 45000, color: '#3B82F6' },
  { channel: '移动应用', performance: 38000, color: '#10B981' },
  { channel: '社交媒体', performance: 32000, color: '#F59E0B' },
  { channel: '直销渠道', performance: 28000, color: '#EF4444' },
  { channel: '合作伙伴', performance: 22000, color: '#8B5CF6' }
]

const countryData: CountryData[] = [
  { country: '中国', revenue: 125000, users: 5420, lat: 35.8617, lng: 104.1954 },
  { country: '美国', revenue: 98000, users: 4230, lat: 37.0902, lng: -95.7129 },
  { country: '日本', revenue: 76000, users: 3100, lat: 36.2048, lng: 138.2529 },
  { country: '德国', revenue: 65000, users: 2800, lat: 51.1657, lng: 10.4515 },
  { country: '英国', revenue: 54000, users: 2300, lat: 55.3781, lng: -3.4360 }
]

// 主要组件
const Dashboard: React.FC = () => {
  const [timeSeriesData, setTimeSeriesData] = useState<TimeSeriesData[]>([])
  const [selectedMetric, setSelectedMetric] = useState<'revenue' | 'users' | 'transactions'>('revenue')
  const [sidebarOpen, setSidebarOpen] = useState(true)

  useEffect(() => {
    setTimeSeriesData(generateTimeSeriesData())
    
    // 模拟实时数据更新
    const interval = setInterval(() => {
      setTimeSeriesData(generateTimeSeriesData())
    }, 10000)
    
    return () => clearInterval(interval)
  }, [])

  // 计算KPI数据
  const calculateKPIs = (): KPIData[] => {
    const latestData = timeSeriesData[timeSeriesData.length - 1]
    const previousData = timeSeriesData[timeSeriesData.length - 2]
    
    if (!latestData || !previousData) {
      return [
        { title: '总用户数', value: '12,543', change: 8.2, icon: <Users className="w-6 h-6" />, color: 'text-blue-600' },
        { title: '总交易数', value: '8,231', change: 12.5, icon: <CreditCard className="w-6 h-6" />, color: 'text-green-600' },
        { title: '总收入', value: '¥1,234,567', change: -2.3, icon: <DollarSign className="w-6 h-6" />, color: 'text-purple-600' },
        { title: '增长率', value: '15.3%', change: 5.8, icon: <TrendingUp className="w-6 h-6" />, color: 'text-orange-600' }
      ]
    }

    const userChange = ((latestData.users - previousData.users) / previousData.users) * 100
    const transactionChange = ((latestData.transactions - previousData.transactions) / previousData.transactions) * 100
    const revenueChange = ((latestData.revenue - previousData.revenue) / previousData.revenue) * 100

    return [
      { 
        title: '总用户数', 
        value: latestData.users.toLocaleString(), 
        change: userChange, 
        icon: <Users className="w-6 h-6" />, 
        color: 'text-blue-600' 
      },
      { 
        title: '总交易数', 
        value: latestData.transactions.toLocaleString(), 
        change: transactionChange, 
        icon: <CreditCard className="w-6 h-6" />, 
        color: 'text-green-600' 
      },
      { 
        title: '总收入', 
        value: `¥${latestData.revenue.toLocaleString()}`, 
        change: revenueChange, 
        icon: <DollarSign className="w-6 h-6" />, 
        color: 'text-purple-600' 
      },
      { 
        title: '增长率', 
        value: `${Math.abs(revenueChange).toFixed(1)}%`, 
        change: revenueChange, 
        icon: <TrendingUp className="w-6 h-6" />, 
        color: 'text-orange-600' 
      }
    ]
  }

  const kpiData = calculateKPIs()

  // 侧边栏组件
  const Sidebar = () => (
    <div className={`${sidebarOpen ? 'w-64' : 'w-16'} bg-slate-900 h-screen fixed left-0 top-0 z-10 transition-all duration-300 flex flex-col`}>
      <div className="p-4 border-b border-slate-700">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
            <BarChart3 className="w-5 h-5 text-white" />
          </div>
          {sidebarOpen && <span className="text-white font-bold text-lg">BI 仪表板</span>}
        </div>
      </div>
      
      <nav className="flex-1 p-4">
        <ul className="space-y-2">
          {[
            { icon: <Home className="w-5 h-5" />, label: '首页', active: true },
            { icon: <BarChart3 className="w-5 h-5" />, label: '分析', active: false },
            { icon: <UsersIcon className="w-5 h-5" />, label: '用户', active: false },
            { icon: <Globe className="w-5 h-5" />, label: '地域', active: false },
            { icon: <Settings className="w-5 h-5" />, label: '设置', active: false }
          ].map((item, index) => (
            <li key={index}>
              <a 
                href="#" 
                className={`flex items-center space-x-3 p-3 rounded-lg transition-colors ${
                  item.active 
                    ? 'bg-blue-600 text-white' 
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`}
              >
                {item.icon}
                {sidebarOpen && <span>{item.label}</span>}
              </a>
            </li>
          ))}
        </ul>
      </nav>
    </div>
  )

  // KPI卡片组件
  const KPICard = ({ data }: { data: KPIData }) => (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-3">
          <div className={`p-3 rounded-lg bg-slate-50 ${data.color}`}>
            {data.icon}
          </div>
          <div>
            <p className="text-slate-600 text-sm font-medium">{data.title}</p>
            <p className="text-2xl font-bold text-slate-900">{data.value}</p>
          </div>
        </div>
        <div className={`flex items-center space-x-1 ${data.change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
          {data.change >= 0 ? (
            <ArrowUpRight className="w-4 h-4" />
          ) : (
            <ArrowDownRight className="w-4 h-4" />
          )}
          <span className="text-sm font-medium">{Math.abs(data.change).toFixed(1)}%</span>
        </div>
      </div>
    </div>
  )

  // 时间序列图表组件
  const TimeSeriesChart = () => (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-lg font-semibold text-slate-900">性能趋势</h3>
        <select 
          value={selectedMetric}
          onChange={(e) => setSelectedMetric(e.target.value as 'revenue' | 'users' | 'transactions')}
          className="px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="revenue">收入</option>
          <option value="users">用户数</option>
          <option value="transactions">交易数</option>
        </select>
      </div>
      <div style={{ width: '100%', height: 300 }}>
        <ResponsiveContainer>
          <LineChart data={timeSeriesData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
            <XAxis 
              dataKey="date" 
              stroke="#64748b"
              tick={{ fontSize: 12 }}
              tickFormatter={(value) => new Date(value).toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' })}
            />
            <YAxis stroke="#64748b" tick={{ fontSize: 12 }} />
            <Tooltip 
              contentStyle={{ 
                backgroundColor: 'white', 
                border: '1px solid #e2e8f0', 
                borderRadius: '8px',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
              }}
              labelFormatter={(value) => new Date(value).toLocaleDateString('zh-CN')}
            />
            <Line 
              type="monotone" 
              dataKey={selectedMetric} 
              stroke="#3B82F6" 
              strokeWidth={3}
              dot={{ fill: '#3B82F6', strokeWidth: 2, r: 4 }}
              activeDot={{ r: 6, stroke: '#3B82F6', strokeWidth: 2, fill: 'white' }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  )

  // 渠道表现图表组件
  const ChannelChart = () => (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <h3 className="text-lg font-semibold text-slate-900 mb-6">渠道表现</h3>
      <div style={{ width: '100%', height: 300 }}>
        <ResponsiveContainer>
          <BarChart data={channelData} layout="horizontal">
            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
            <XAxis type="number" stroke="#64748b" tick={{ fontSize: 12 }} />
            <YAxis 
              type="category" 
              dataKey="channel" 
              stroke="#64748b" 
              tick={{ fontSize: 12 }}
              width={80}
            />
            <Tooltip 
              contentStyle={{ 
                backgroundColor: 'white', 
                border: '1px solid #e2e8f0', 
                borderRadius: '8px',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
              }}
            />
            <Bar dataKey="performance" fill="#3B82F6" radius={[0, 4, 4, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  )

  // 国家分布组件
  const CountryDistribution = () => (
    <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <h3 className="text-lg font-semibold text-slate-900 mb-6">国家分布</h3>
      <div className="space-y-4">
        {countryData.map((item, index) => (
          <div key={index} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
            <div className="flex items-center space-x-3">
              <div className="w-3 h-3 rounded-full bg-blue-600"></div>
              <span className="font-medium text-slate-900">{item.country}</span>
            </div>
            <div className="text-right">
              <p className="font-semibold text-slate-900">¥{item.revenue.toLocaleString()}</p>
              <p className="text-sm text-slate-600">{item.users} 用户</p>
            </div>
          </div>
        ))}
      </div>
      
      {/* 简化的世界地图可视化 */}
      <div className="mt-6">
        <div style={{ width: '100%', height: 200 }}>
          <ResponsiveContainer>
            <PieChart>
              <Pie
                data={countryData}
                dataKey="revenue"
                nameKey="country"
                cx="50%"
                cy="50%"
                outerRadius={80}
                label={({ country, percent }) => `${country} ${(percent * 100).toFixed(0)}%`}
              >
                {countryData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={channelData[index % channelData.length].color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )

  // 顶部导航栏
  const TopNavbar = () => (
    <div className="bg-white border-b border-slate-200 p-4 flex items-center justify-between">
      <div className="flex items-center space-x-4">
        <button 
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="p-2 rounded-lg hover:bg-slate-100"
        >
          <BarChart3 className="w-5 h-5 text-slate-600" />
        </button>
        <h1 className="text-xl font-semibold text-slate-900">商业智能仪表板</h1>
      </div>
      
      <div className="flex items-center space-x-4">
        <div className="relative">
          <Search className="w-5 h-5 text-slate-400 absolute left-3 top-1/2 transform -translate-y-1/2" />
          <input 
            type="text" 
            placeholder="搜索..." 
            className="pl-10 pr-4 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
        <button className="p-2 rounded-lg hover:bg-slate-100">
          <Bell className="w-5 h-5 text-slate-600" />
        </button>
        <button className="p-2 rounded-lg hover:bg-slate-100">
          <Calendar className="w-5 h-5 text-slate-600" />
        </button>
      </div>
    </div>
  )

  return (
    <div className="min-h-screen bg-slate-50">
      <Sidebar />
      
      <div className={`${sidebarOpen ? 'ml-64' : 'ml-16'} transition-all duration-300`}>
        <TopNavbar />
        
        <div className="p-6">
          {/* KPI 卡片 */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {kpiData.map((kpi, index) => (
              <KPICard key={index} data={kpi} />
            ))}
          </div>
          
          {/* 主要图表区域 */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <div className="lg:col-span-2">
              <TimeSeriesChart />
            </div>
          </div>
          
          {/* 次要图表区域 */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <ChannelChart />
            <CountryDistribution />
          </div>
        </div>
      </div>
    </div>
  )
}

export default Dashboard 