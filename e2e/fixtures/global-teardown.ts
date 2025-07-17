import { FullConfig } from '@playwright/test';

async function globalTeardown(config: FullConfig) {
  console.log('🧹 Starting global teardown for Playwright tests...');
  
  try {
    // Import test data manager
    const { testDataManager } = require('./test-data');
    
    // Clean up test data
    await testDataManager.cleanup();
    
    console.log('✅ Global teardown completed successfully');
  } catch (error) {
    console.error('⚠️  Global teardown failed:', error);
    // Don't throw error in teardown to avoid masking test failures
  }
}

export default globalTeardown;