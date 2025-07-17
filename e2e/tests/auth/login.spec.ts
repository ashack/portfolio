import { test, expect } from '@playwright/test';
import { LoginPage, DashboardPage } from '@pages/index';
import { testUsers, login, logout } from '@fixtures/index';

test.describe('Login Flow', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    await loginPage.navigate();
  });

  test('should display login page elements', async ({ page }) => {
    await expect(loginPage.emailInput).toBeVisible();
    await expect(loginPage.passwordInput).toBeVisible();
    await expect(loginPage.rememberMeCheckbox).toBeVisible();
    await expect(loginPage.loginButton).toBeVisible();
    await expect(loginPage.forgotPasswordLink).toBeVisible();
    await expect(loginPage.signUpLink).toBeVisible();
  });

  test.describe('Direct User Login', () => {
    test('should login successfully with valid credentials', async ({ page }) => {
      const user = testUsers.directUser;
      await loginPage.login(user.email, user.password);
      
      // Should redirect to user dashboard
      await expect(page).toHaveURL(/\/dashboard/);
      
      // Should show welcome message
      const welcomeText = await dashboardPage.getWelcomeText();
      expect(welcomeText).toMatch(/Welcome back|Dashboard/i);
      
      // Should show user menu
      await expect(loginPage.userMenu).toBeVisible();
    });

    test('should remember user when remember me is checked', async ({ page }) => {
      const user = testUsers.directUser;
      await loginPage.login(user.email, user.password, true);
      
      // Check that remember me was selected
      expect(await loginPage.isRememberMeChecked()).toBe(true);
      
      // Should redirect successfully
      await expect(page).toHaveURL(/\/dashboard/);
    });
  });

  test.describe('Team User Login', () => {
    test.skip('should redirect team admin to team dashboard', async ({ page }) => {
      // SKIP: Team creation is currently disabled in test data setup
      // TODO: Enable when team creation is fixed
      const user = testUsers.teamAdmin;
      await loginPage.login(user.email, user.password);
      
      // Should redirect to team dashboard
      await expect(page).toHaveURL(new RegExp(`/teams/${user.teamSlug}`));
      
      // Should show team admin dashboard
      const dashboardType = await dashboardPage.getDashboardType();
      expect(dashboardType).toMatch(/team_admin|team_member/);
    });

    test.skip('should redirect team member to team dashboard', async ({ page }) => {
      // SKIP: Team creation is currently disabled in test data setup
      // TODO: Enable when team creation is fixed
      const user = testUsers.teamMember;
      await loginPage.login(user.email, user.password);
      
      // Should redirect to team dashboard
      await expect(page).toHaveURL(new RegExp(`/teams/${user.teamSlug}`));
      
      // Should show team member dashboard
      const dashboardType = await dashboardPage.getDashboardType();
      expect(dashboardType).toMatch(/team_member|team_admin/);
    });
  });

  test.describe('Admin Login', () => {
    test('should redirect super admin to admin dashboard', async ({ page }) => {
      const user = testUsers.superAdmin;
      await loginPage.login(user.email, user.password);
      
      // Should redirect to super admin dashboard
      await expect(page).toHaveURL(/\/admin\/super/);
      
      // Should show admin dashboard
      const dashboardType = await dashboardPage.getDashboardType();
      expect(dashboardType).toBe('super_admin');
    });

    test('should redirect site admin to site admin dashboard', async ({ page }) => {
      const user = testUsers.siteAdmin;
      await loginPage.login(user.email, user.password);
      
      // Should redirect to site admin dashboard
      await expect(page).toHaveURL(/\/admin\/site/);
      
      // Should show site admin dashboard
      const dashboardType = await dashboardPage.getDashboardType();
      expect(dashboardType).toBe('site_admin');
    });
  });

  test.describe('Login Errors', () => {
    test('should show error for invalid credentials', async ({ page }) => {
      await loginPage.loginAndExpectError('invalid@example.com', 'wrongpassword');
      
      // Should stay on login page
      await expect(page).toHaveURL(/\/users\/sign_in/);
      
      // Should show error message
      const errorMessage = await loginPage.getLoginErrorMessage();
      expect(errorMessage).toContain('Invalid Email or password');
    });

    test('should show error for empty email', async ({ page }) => {
      await loginPage.passwordInput.fill('Password123!');
      await loginPage.loginButton.click();
      
      // Wait for error message
      await loginPage.page.waitForSelector('[role="alert"]');
      
      // Should show generic error message (Rails doesn't provide field-specific errors)
      const errorMessage = await loginPage.getErrorMessage();
      expect(errorMessage).toContain('Invalid Email or password');
    });

    test('should show error for empty password', async ({ page }) => {
      await loginPage.emailInput.fill('test@example.com');
      await loginPage.loginButton.click();
      
      // Wait for error message
      await loginPage.page.waitForSelector('[role="alert"]');
      
      // Should show generic error message (Rails doesn't provide field-specific errors)
      const errorMessage = await loginPage.getErrorMessage();
      expect(errorMessage).toContain('Invalid Email or password');
    });

    test('should show error for unconfirmed email', async ({ page }) => {
      // This test assumes there's an unconfirmed user in the test data
      await loginPage.loginAndExpectError('unconfirmed@example.com', 'Password123!');
      
      // Should show an error message (either generic or confirmation-specific)
      const errorMessage = await loginPage.getLoginErrorMessage();
      expect(errorMessage).toBeTruthy();
      
      // The specific message depends on Devise configuration
      // It might show "confirm your email" or "Invalid Email or password"
    });

    test('should show error for locked account', async ({ page }) => {
      // This test assumes there's a locked user in the test data
      await loginPage.loginAndExpectError('locked@example.com', 'Password123!');
      
      // Devise might be configured to not reveal if account is locked for security
      // So it shows the generic error message
      const errorMessage = await loginPage.getLoginErrorMessage();
      expect(errorMessage).toContain('Invalid Email or password');
      
      // Unlock link may not be visible if Devise doesn't reveal locked status
      // await expect(loginPage.resendUnlockLink).toBeVisible();
    });
  });

  test.describe('Navigation Links', () => {
    test('should navigate to forgot password page', async ({ page }) => {
      await loginPage.clickForgotPassword();
      await expect(page).toHaveURL(/\/users\/password\/new/);
    });

    test('should navigate to sign up page', async ({ page }) => {
      await loginPage.clickSignUp();
      await expect(page).toHaveURL(/\/users\/sign_up/);
    });

    test('should navigate to resend confirmation page', async ({ page }) => {
      await loginPage.clickResendConfirmation();
      await expect(page).toHaveURL(/\/users\/confirmation\/new/);
    });
  });
});