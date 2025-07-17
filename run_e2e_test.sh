#!/bin/bash

echo "🔧 Preparing E2E test environment..."

# Setup E2E test database
echo "📊 Setting up E2E test database..."
bundle exec rails db:e2e:prepare

# Run e2e test
echo "🧪 Running e2e tests..."
npm run e2e -- "$@"