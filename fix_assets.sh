#\!/bin/bash

echo "Stopping all processes..."
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
pkill -f "rails" 2>/dev/null || true
pkill -f "tailwindcss" 2>/dev/null || true

echo "Cleaning all caches and temporary files..."
rm -rf tmp/cache/*
rm -rf tmp/miniprofiler/*
rm -rf public/assets/
rm -f public/assets/.manifest.json

echo "Clearing browser cache is recommended\!"
echo "Hard refresh with: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows/Linux)"

echo ""
echo "Now start the server with:"
echo "bin/dev"
