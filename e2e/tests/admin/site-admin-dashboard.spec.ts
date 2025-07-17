import { test, expect } from '@playwright/test';
import { LoginPage, DashboardPage } from '@pages/index';
import { testUsers } from '@fixtures/index';

test.describe('Site Admin Dashboard', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    
    // Login as site admin
    await loginPage.navigate();
    await loginPage.login(testUsers.siteAdmin.email, testUsers.siteAdmin.password);
    
    // Should redirect to site admin dashboard
    await expect(page).toHaveURL(/\/admin\/site|\/redirect_after_sign_in/);
  });

  test('should display site admin dashboard', async ({ page }) => {
    // Navigate to site admin dashboard if not already there
    if (!page.url().includes('/admin/site')) {
      await dashboardPage.navigateToSiteAdminDashboard();
    }
    
    // Check dashboard type
    const dashboardType = await dashboardPage.getDashboardType();
    expect(dashboardType).toBe('site_admin');
    
    // Check for admin-specific elements
    await expect(page.locator('h1')).toContainText(/Site Admin|Dashboard/i);
  });

  test('should access user management with limited permissions', async ({ page }) => {
    await dashboardPage.navigateToSiteAdminDashboard();
    
    // Site admin can view users
    const usersLink = page.locator('a:has-text("Users")').first();
    if (await usersLink.isVisible()) {
      await usersLink.click();
      await expect(page).toHaveURL(/\/admin\/site\/users/);
    }
    
    // Should NOT see create team buttons
    const createTeamButton = page.locator('button:has-text("Create Team"), a:has-text("Create Team")');
    expect(await createTeamButton.count()).toBe(0);
  });

  test('should access support tools', async ({ page }) => {
    await dashboardPage.navigateToSiteAdminDashboard();
    await dashboardPage.navigateToSupportTickets();
    
    await expect(page).toHaveURL(/\/admin\/site\/support/);
    await expect(page.locator('h1')).toContainText(/Support/i);
  });

  test('should view activity logs', async ({ page }) => {
    await dashboardPage.navigateToSiteAdminDashboard();
    
    // Look for activity link
    const activityLink = page.locator('a:has-text("Activity")').first();
    if (await activityLink.isVisible()) {
      await activityLink.click();
      await expect(page.locator('h1')).toContainText(/Activity/i);
    }
  });

  test('should NOT access billing information', async ({ page }) => {
    await dashboardPage.navigateToSiteAdminDashboard();
    
    // Should not see billing links
    const billingLink = page.locator('a:has-text("Billing")');
    expect(await billingLink.count()).toBe(0);
  });

  test('should NOT access system settings', async ({ page }) => {
    await dashboardPage.navigateToSiteAdminDashboard();
    
    // Should not see settings link
    const settingsLink = page.locator('a[href*="/settings"]');
    const visibleSettings = await settingsLink.filter({ hasText: /System Settings/i }).count();
    expect(visibleSettings).toBe(0);
  });

  test('should handle user status changes', async ({ page }) => {
    await dashboardPage.navigateToSiteAdminDashboard();
    
    // Navigate to users
    const usersLink = page.locator('a:has-text("Users")').first();
    await usersLink.click();
    
    // Find a user status button
    const statusButton = page.locator('button:has-text("Active"), button:has-text("Inactive")').first();
    if (await statusButton.isVisible()) {
      const originalText = await statusButton.textContent();
      await statusButton.click();
      
      // Wait for status change
      await page.waitForTimeout(1000);
      
      // Status should have changed
      const newText = await statusButton.textContent();
      expect(newText).not.toBe(originalText);
    }
  });
});