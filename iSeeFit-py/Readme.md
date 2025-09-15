# Business Intelligence Dashboard

This is a responsive Business Intelligence dashboard built with Next.js and TypeScript.

## Features

- 📊 **Real-time KPI monitoring**: shows total users, transactions, revenue, and growth rate
- 📈 **Time series chart**: visualizes performance trends with metric switching
- 📊 **Channel analysis**: horizontal bar chart for channel performance
- 🌍 **Geographic distribution**: revenue and users by country
- 🎛️ **Sidebar navigation**: collapsible left sidebar
- 📱 **Responsive design**: mobile and desktop friendly
- 🔄 **Simulated real-time data**: updates every 10 seconds

## Tech Stack

- **Framework**: Next.js 14
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Charts**: Recharts
- **Icons**: Lucide React

## Install and Run

1. Install dependencies:
```bash
npm install
```

2. Start the dev server:
```bash
npm run dev
```

3. Open [http://localhost:3000](http://localhost:3000)

## Project Structure

```
├── app/
│   ├── layout.tsx      # App layout
│   ├── page.tsx        # Main page
│   └── globals.css     # Global styles
├── dashboard.tsx       # Dashboard component
├── package.json        # Dependencies
├── tailwind.config.js  # Tailwind config
├── tsconfig.json       # TypeScript config
└── next.config.js      # Next.js config
```

## Key Components

### KPI Cards
- Display key business metrics
- Include trend and percentage change
- Colored icons and motion effects

### Time Series Chart
- 30-day historical data
- Switch between revenue/users/transactions
- Interactive tooltip

### Channel Analysis Chart
- Horizontal bar chart
- Channel performance comparison
- Color coding by channel

### Geographic Distribution
- Country list with metrics
- Pie chart revenue distribution
- Real-time data updates

## Customization and Extension

### Modify data source
Edit the following in `dashboard.tsx`:
- `generateTimeSeriesData()`: time-series data
- `channelData`: channel data
- `countryData`: country data

### Add new KPIs
Add metrics in the `calculateKPIs()` function.

### Customize styles
Edit `tailwind.config.js` or use custom CSS classes in components.

## Build for Production

```bash
npm run build
npm start
```

## License

MIT License

