#!/bin/bash

echo "🚀 Starting Razorpay Backend Server..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found. Creating from template..."
    cp env.example .env
    echo "📝 Please edit .env file with your Razorpay API keys before starting."
    echo "   You can get your keys from: https://dashboard.razorpay.com/settings/api-keys"
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start the server
echo "✅ Starting server on http://localhost:3000"
echo "📊 Health check: http://localhost:3000/health"
echo "🔧 Environment: $(grep NODE_ENV .env | cut -d '=' -f2 || echo 'development')"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

npm run dev 