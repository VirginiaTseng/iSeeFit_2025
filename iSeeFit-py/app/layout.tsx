import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Business Intelligence Dashboard',
  description: 'A responsive BI dashboard built with Next.js and TypeScript',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
} 