#!/bin/bash

# iSeeFit development start script
echo "🍎 Starting iSeeFit development environment..."

# Check Node.js version
echo "Checking Node.js version..."
node --version

# Start backend service
echo "Starting backend service..."
cd iSeeFit-backend
npm run dev &
BACKEND_PID=$!

# Wait for backend to start
sleep 3

# Start frontend service
echo "Starting frontend service..."
cd ../iSeeFit-frontend
npm run dev &
FRONTEND_PID=$!

echo "✅ Services started!"
echo "📱 Frontend: http://localhost:5173"
echo "🔧 Backend: http://localhost:3001"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for user interrupt
wait

# Cleanup processes
echo "Stopping services..."
kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
echo "Services stopped"
