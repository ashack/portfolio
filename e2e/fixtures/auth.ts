import { test as base, Page } from '@playwright/test';
import { LoginPage } from '../pages/LoginPage';

// Define user types for testing
export interface TestUser {
  email: string;
  password: string;
  type: 'super_admin' | 'site_admin' | 'direct' | 'team_admin' | 'team_member' | 'enterprise_admin' | 'enterprise_member';
  teamSlug?: string;
  enterpriseSlug?: string;
}

// Test users from environment variables
export const testUsers: Record<string, TestUser> = {
  superAdmin: {
    email: process.env.TEST_SUPER_ADMIN_EMAIL || 'super@example.com',
    password: process.env.TEST_SUPER_ADMIN_PASSWORD || 'Password123!',
    type: 'super_admin'
  },
  siteAdmin: {
    email: process.env.TEST_SITE_ADMIN_EMAIL || 'site@example.com',
    password: process.env.TEST_SITE_ADMIN_PASSWORD || 'Password123!',
    type: 'site_admin'
  },
  directUser: {
    email: process.env.TEST_DIRECT_USER_EMAIL || 'direct@example.com',
    password: process.env.TEST_DIRECT_USER_PASSWORD || 'Password123!',
    type: 'direct'
  },
  teamAdmin: {
    email: process.env.TEST_TEAM_ADMIN_EMAIL || 'teamadmin@example.com',
    password: process.env.TEST_TEAM_ADMIN_PASSWORD || 'Password123!',
    type: 'team_admin',
    teamSlug: 'test-team'
  },
  teamMember: {
    email: process.env.TEST_TEAM_MEMBER_EMAIL || 'member@example.com',
    password: process.env.TEST_TEAM_MEMBER_PASSWORD || 'Password123!',
    type: 'team_member',
    teamSlug: 'test-team'
  },
  enterpriseAdmin: {
    email: process.env.TEST_ENTERPRISE_ADMIN_EMAIL || 'entadmin@example.com',
    password: process.env.TEST_ENTERPRISE_ADMIN_PASSWORD || 'Password123!',
    type: 'enterprise_admin',
    enterpriseSlug: 'test-enterprise'
  }
};

// Edge case test users
export const edgeCaseUsers = {
  unconfirmed: {
    email: 'unconfirmed@example.com',
    password: 'Password123!',
    type: 'direct' as const
  },
  locked: {
    email: 'locked@example.com',
    password: 'Password123!',
    type: 'direct' as const
  },
  inactive: {
    email: 'inactive@example.com',
    password: 'Password123!',
    type: 'direct' as const
  },
  specialChars: {
    email: 'user+test@example.com',
    password: 'Password123!',
    type: 'direct' as const
  },
  longPassword: {
    email: 'longpass@example.com',
    password: 'A'.repeat(128) + '1!',
    type: 'direct' as const
  }
};

// Authentication helper functions
export async function login(page: Page, user: TestUser): Promise<void> {
  const loginPage = new LoginPage(page);
  await loginPage.navigate();
  await loginPage.login(user.email, user.password);
  
  // Wait for redirect based on user type
  switch (user.type) {
    case 'super_admin':
      await page.waitForURL('**/admin/super**');
      break;
    case 'site_admin':
      await page.waitForURL('**/admin/site**');
      break;
    case 'direct':
      await page.waitForURL('**/dashboard**');
      break;
    case 'team_admin':
    case 'team_member':
      await page.waitForURL(`**/teams/${user.teamSlug}**`);
      break;
    case 'enterprise_admin':
    case 'enterprise_member':
      await page.waitForURL(`**/enterprise/${user.enterpriseSlug}**`);
      break;
  }
}

// Extended test fixture with authentication
export const authenticatedTest = base.extend<{
  authenticatedPage: Page;
  userType: keyof typeof testUsers;
}>({
  userType: ['directUser', { option: true }], // Default to direct user
  
  authenticatedPage: async ({ page, userType }, use) => {
    // Login with the specified user type
    const user = testUsers[userType];
    await login(page, user);
    
    // Use the authenticated page in tests
    await use(page);
    
    // Cleanup: logout after test
    const basePage = new (await import('../pages/BasePage')).BasePage(page);
    await basePage.logout();
  }
});

// Helper to create authenticated context (for API requests)
export async function getAuthenticatedContext(page: Page, user: TestUser) {
  await login(page, user);
  
  // Get cookies after login
  const cookies = await page.context().cookies();
  
  // Return context with auth cookies
  return {
    cookies,
    headers: {
      'X-CSRF-Token': await getCSRFToken(page)
    }
  };
}

// Helper to get CSRF token
export async function getCSRFToken(page: Page): Promise<string> {
  const token = await page.locator('meta[name="csrf-token"]').getAttribute('content');
  return token || '';
}

// Helper to check if user is logged in
export async function isLoggedIn(page: Page): Promise<boolean> {
  const userMenu = page.locator('[data-testid="user-menu"]');
  return await userMenu.isVisible();
}

// Helper to logout
export async function logout(page: Page): Promise<void> {
  if (await isLoggedIn(page)) {
    const basePage = new (await import('../pages/BasePage')).BasePage(page);
    await basePage.logout();
    await page.waitForURL('**/users/sign_in');
  }
}