#!/bin/bash

# Kill any existing Rails processes
pkill -f "rails server" || true
pkill -f "foreman" || true
pkill -f "tailwindcss:watch" || true

# Clean up any precompiled assets
rm -rf public/assets
rm -rf app/assets/builds/tailwind.css

# Build Tailwind CSS
bundle exec rails tailwindcss:build

# Start development server
echo "Starting development server..."
echo "Access the application at: http://localhost:3000"
./bin/dev