import { Page, BrowserContext } from '@playwright/test';
import { LoginPage } from '@pages/LoginPage';
import { testUsers } from '@fixtures/index';

export interface AuthenticatedUser {
  email: string;
  password: string;
  userType: 'direct' | 'team_admin' | 'team_member' | 'super_admin' | 'site_admin' | 'enterprise';
  expectedRedirect: RegExp;
}

export class AuthHelpers {
  /**
   * Quick login helper that bypasses UI for faster test setup
   */
  static async quickLogin(page: Page, email: string, password: string): Promise<void> {
    // Use API endpoint or direct session manipulation for faster login
    await page.request.post('/users/sign_in', {
      data: {
        'user[email]': email,
        'user[password]': password,
        'user[remember_me]': '0',
        'authenticity_token': await this.getAuthenticityToken(page)
      }
    });
    
    // Navigate to trigger session load
    await page.goto('/');
  }

  /**
   * Get CSRF token for API requests
   */
  static async getAuthenticityToken(page: Page): Promise<string> {
    await page.goto('/users/sign_in');
    const token = await page.locator('meta[name="csrf-token"]').getAttribute('content');
    return token || '';
  }

  /**
   * Login via UI and verify redirect
   */
  static async loginAndVerifyRedirect(
    page: Page, 
    user: AuthenticatedUser
  ): Promise<void> {
    const loginPage = new LoginPage(page);
    await loginPage.navigate();
    await loginPage.login(user.email, user.password);
    await page.waitForURL(user.expectedRedirect);
  }

  /**
   * Get user type configuration
   */
  static getUserConfig(userType: string): AuthenticatedUser {
    const configs: Record<string, AuthenticatedUser> = {
      direct: {
        email: testUsers.directUser.email,
        password: testUsers.directUser.password,
        userType: 'direct',
        expectedRedirect: /\/dashboard/
      },
      team_admin: {
        email: testUsers.teamAdmin.email,
        password: testUsers.teamAdmin.password,
        userType: 'team_admin',
        expectedRedirect: /\/teams\/[\w-]+\/admin/
      },
      team_member: {
        email: testUsers.teamMember.email,
        password: testUsers.teamMember.password,
        userType: 'team_member',
        expectedRedirect: /\/teams\/[\w-]+/
      },
      super_admin: {
        email: testUsers.superAdmin.email,
        password: testUsers.superAdmin.password,
        userType: 'super_admin',
        expectedRedirect: /\/admin\/super/
      },
      site_admin: {
        email: testUsers.siteAdmin.email,
        password: testUsers.siteAdmin.password,
        userType: 'site_admin',
        expectedRedirect: /\/admin\/site/
      }
    };

    return configs[userType];
  }

  /**
   * Verify user is logged out
   */
  static async verifyLoggedOut(page: Page): Promise<boolean> {
    // Check if redirected to login page
    const url = page.url();
    if (!url.includes('/users/sign_in')) {
      return false;
    }

    // Check if login form is visible
    const loginForm = page.locator('[data-testid="login-email"]');
    return await loginForm.isVisible();
  }

  /**
   * Clear all auth cookies
   */
  static async clearAuthCookies(context: BrowserContext): Promise<void> {
    await context.clearCookies();
  }

  /**
   * Check if session is valid
   */
  static async isSessionValid(page: Page): Promise<boolean> {
    const response = await page.request.get('/dashboard', {
      failOnStatusCode: false
    });
    return response.status() === 200;
  }

  /**
   * Simulate session timeout
   */
  static async simulateSessionTimeout(context: BrowserContext): Promise<void> {
    const cookies = await context.cookies();
    const sessionCookie = cookies.find(c => c.name === '_saas_ror_starter_session');
    
    if (sessionCookie) {
      // Set cookie to expired
      await context.addCookies([{
        ...sessionCookie,
        expires: Math.floor(Date.now() / 1000) - 3600 // 1 hour ago
      }]);
    }
  }

  /**
   * Get current user info from page
   */
  static async getCurrentUserInfo(page: Page): Promise<{
    email?: string;
    role?: string;
    dashboardType?: string;
  }> {
    // This would parse user info from the page
    // Implementation depends on how user info is displayed
    const userMenu = page.locator('[data-testid="user-menu"]');
    if (await userMenu.isVisible()) {
      const email = await userMenu.locator('.user-email').textContent();
      return { email: email || undefined };
    }
    return {};
  }

  /**
   * Wait for authentication redirect
   */
  static async waitForAuthRedirect(page: Page, timeout: number = 5000): Promise<void> {
    await Promise.race([
      page.waitForURL(/\/dashboard/, { timeout }),
      page.waitForURL(/\/teams\//, { timeout }),
      page.waitForURL(/\/admin\//, { timeout }),
      page.waitForURL(/\/enterprise\//, { timeout })
    ]);
  }

  /**
   * Create authenticated context for a specific user type
   */
  static async createAuthenticatedContext(
    browser: any,
    userType: string
  ): Promise<{ context: BrowserContext; page: Page }> {
    const context = await browser.newContext();
    const page = await context.newPage();
    
    const user = this.getUserConfig(userType);
    await this.quickLogin(page, user.email, user.password);
    
    return { context, page };
  }

  /**
   * Test rate limiting
   */
  static async testRateLimit(
    page: Page,
    attempts: number = 6
  ): Promise<boolean> {
    const loginPage = new LoginPage(page);
    await loginPage.navigate();

    for (let i = 0; i < attempts; i++) {
      await loginPage.loginAndExpectError(
        `attacker${i}@example.com`,
        'wrongpassword'
      );
      await page.waitForTimeout(100);
    }

    const errorMessage = await loginPage.getLoginErrorMessage();
    return errorMessage.toLowerCase().includes('too many') ||
           errorMessage.toLowerCase().includes('rate limit');
  }

  /**
   * Generate secure test password
   */
  static generateSecurePassword(length: number = 12): string {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#$%^&*';
    const all = uppercase + lowercase + numbers + symbols;
    
    let password = '';
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += symbols[Math.floor(Math.random() * symbols.length)];
    
    for (let i = 4; i < length; i++) {
      password += all[Math.floor(Math.random() * all.length)];
    }
    
    return password.split('').sort(() => Math.random() - 0.5).join('');
  }
}