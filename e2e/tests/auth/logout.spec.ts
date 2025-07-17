import { test, expect } from '@playwright/test';
import { LoginPage, DashboardPage, BasePage } from '@pages/index';
import { testUsers, login } from '@fixtures/index';

test.describe('Logout Flow', () => {
  let basePage: BasePage;
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    basePage = new BasePage(page);
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
  });

  test.describe('Direct User Logout', () => {
    test.beforeEach(async ({ page }) => {
      // Login as direct user
      await login(page, testUsers.directUser);
    });

    test('should logout successfully from user menu', async ({ page }) => {
      // Verify user is logged in
      await expect(basePage.userMenu).toBeVisible();
      
      // Logout
      await basePage.logout();
      
      // Should redirect to login page
      await expect(page).toHaveURL(/\/users\/sign_in/);
      
      // User menu should not be visible
      await expect(basePage.userMenu).not.toBeVisible();
      
      // Should show logged out message
      const flashMessage = await basePage.getFlashMessageText();
      expect(flashMessage).toContain('Signed out successfully');
    });

    test('should clear session after logout', async ({ page }) => {
      // Logout
      await basePage.logout();
      
      // Try to access protected page
      await page.goto('/dashboard');
      
      // Should redirect to login
      await expect(page).toHaveURL(/\/users\/sign_in/);
    });
  });

  test.describe('Team User Logout', () => {
    test('should logout team admin successfully', async ({ page }) => {
      // Login as team admin
      await login(page, testUsers.teamAdmin);
      
      // Verify on team dashboard
      await expect(page).toHaveURL(new RegExp(`/teams/${testUsers.teamAdmin.teamSlug}`));
      
      // Logout
      await basePage.logout();
      
      // Should redirect to login
      await expect(page).toHaveURL(/\/users\/sign_in/);
    });

    test('should logout team member successfully', async ({ page }) => {
      // Login as team member
      await login(page, testUsers.teamMember);
      
      // Logout
      await basePage.logout();
      
      // Should redirect to login
      await expect(page).toHaveURL(/\/users\/sign_in/);
    });
  });

  test.describe('Admin Logout', () => {
    test('should logout super admin successfully', async ({ page }) => {
      // Login as super admin
      await login(page, testUsers.superAdmin);
      
      // Verify on admin dashboard
      await expect(page).toHaveURL(/\/admin\/super/);
      
      // Logout
      await basePage.logout();
      
      // Should redirect to login
      await expect(page).toHaveURL(/\/users\/sign_in/);
      
      // Try to access admin page
      await page.goto('/admin/super');
      
      // Should redirect to login
      await expect(page).toHaveURL(/\/users\/sign_in/);
    });

    test('should logout site admin successfully', async ({ page }) => {
      // Login as site admin
      await login(page, testUsers.siteAdmin);
      
      // Logout
      await basePage.logout();
      
      // Should redirect to login
      await expect(page).toHaveURL(/\/users\/sign_in/);
    });
  });

  test.describe('Logout Edge Cases', () => {
    test('should handle logout when already logged out', async ({ page }) => {
      // Navigate to login page (not logged in)
      await loginPage.navigate();
      
      // Try to access logout URL directly
      await page.goto('/users/sign_out');
      
      // Should redirect to login without error
      await expect(page).toHaveURL(/\/users\/sign_in/);
    });

    test('should maintain logout state across browser refresh', async ({ page }) => {
      // Login and logout
      await login(page, testUsers.directUser);
      await basePage.logout();
      
      // Refresh page
      await page.reload();
      
      // Should still be on login page
      await expect(page).toHaveURL(/\/users\/sign_in/);
      
      // User menu should not be visible
      await expect(basePage.userMenu).not.toBeVisible();
    });

    test('should logout from any page', async ({ page }) => {
      // Login
      await login(page, testUsers.directUser);
      
      // Navigate to profile page
      await basePage.navigateToProfile();
      
      // Logout from profile page
      await basePage.logout();
      
      // Should redirect to login
      await expect(page).toHaveURL(/\/users\/sign_in/);
    });
  });

  test.describe('Session Timeout', () => {
    test.skip('should redirect to login on session timeout', async ({ page }) => {
      // This test would require manipulating session timeout
      // Skipped as it requires server-side configuration
    });
  });
});