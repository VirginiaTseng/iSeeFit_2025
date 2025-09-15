import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: '商业智能仪表板',
  description: '使用Next.js和TypeScript构建的响应式商业智能仪表板',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-CN">
      <body>{children}</body>
    </html>
  )
} 