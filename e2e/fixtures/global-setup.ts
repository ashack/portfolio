import { chromium, FullConfig } from '@playwright/test';
import * as dotenv from 'dotenv';

// Load test environment variables
dotenv.config({ path: '.env.test' });

async function globalSetup(config: FullConfig) {
  console.log('🚀 Starting global setup for Playwright tests...');
  
  // You can perform any global setup here, such as:
  // - Database seeding
  // - Creating test users
  // - Setting up test data
  // - Starting external services
  
  // For now, we'll just ensure the Rails server is ready
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  try {
    // Wait for Rails server to be ready
    const maxRetries = 30;
    let retries = 0;
    let serverReady = false;
    
    while (retries < maxRetries && !serverReady) {
      try {
        await page.goto(process.env.BASE_URL || 'http://localhost:3001', {
          waitUntil: 'domcontentloaded',
          timeout: 5000
        });
        serverReady = true;
        console.log('✅ Rails server is ready');
      } catch (error) {
        retries++;
        console.log(`⏳ Waiting for Rails server... (attempt ${retries}/${maxRetries})`);
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    }
    
    if (!serverReady) {
      throw new Error('Rails server failed to start');
    }
    
    // Set up test data
    console.log('🌱 Setting up test data...');
    
    // Import test data manager
    const { testDataManager } = require('./test-data');
    
    // Setup test environment with all necessary data
    await testDataManager.setupTestEnvironment();
    
    console.log('✅ Test data setup complete');
    
  } catch (error) {
    console.error('❌ Global setup failed:', error);
    throw error;
  } finally {
    await browser.close();
  }
  
  console.log('✅ Global setup completed successfully');
}

export default globalSetup;