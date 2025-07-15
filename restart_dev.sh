#\!/bin/bash
# Kill any existing processes
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
pkill -f "bin/rails server" 2>/dev/null || true
pkill -f "tailwindcss" 2>/dev/null || true

# Clear caches
rm -rf tmp/cache/*
rm -rf public/assets/

echo "Starting development server with bin/dev..."
echo "This will handle both Rails and asset compilation"
echo "Use Ctrl+C to stop"
