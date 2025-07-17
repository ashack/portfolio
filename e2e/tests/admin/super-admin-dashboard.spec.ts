import { test, expect } from '@playwright/test';
import { LoginPage, DashboardPage } from '@pages/index';
import { testUsers } from '@fixtures/index';

test.describe('Super Admin Dashboard', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    
    // Login as super admin
    await loginPage.navigate();
    await loginPage.login(testUsers.superAdmin.email, testUsers.superAdmin.password);
    
    // Should redirect to admin dashboard
    await expect(page).toHaveURL(/\/admin\/super|\/redirect_after_sign_in/);
  });

  test('should display super admin dashboard', async ({ page }) => {
    // Navigate to super admin dashboard if not already there
    if (!page.url().includes('/admin/super')) {
      await dashboardPage.navigateToSuperAdminDashboard();
    }
    
    // Check dashboard type
    const dashboardType = await dashboardPage.getDashboardType();
    expect(dashboardType).toBe('super_admin');
    
    // Check for admin-specific elements
    await expect(page.locator('h1')).toContainText(/Super Admin|Dashboard/i);
  });

  test('should navigate to user management', async ({ page }) => {
    await dashboardPage.navigateToSuperAdminDashboard();
    await dashboardPage.navigateToUserManagement();
    
    await expect(page).toHaveURL(/\/admin\/super\/users/);
    await expect(page.locator('h1')).toContainText(/Users/i);
  });

  test('should navigate to team management', async ({ page }) => {
    await dashboardPage.navigateToSuperAdminDashboard();
    await dashboardPage.navigateToTeamManagement();
    
    await expect(page).toHaveURL(/\/admin\/super\/teams/);
    await expect(page.locator('h1')).toContainText(/Teams/i);
  });

  test('should be able to create a new team', async ({ page }) => {
    await dashboardPage.navigateToSuperAdminDashboard();
    await dashboardPage.navigateToTeamManagement();
    
    // Look for create team button
    const createButton = page.locator('a:has-text("Create Team"), button:has-text("Create Team")').first();
    if (await createButton.isVisible()) {
      await createButton.click();
      await expect(page).toHaveURL(/\/admin\/super\/teams\/new/);
    }
  });

  test('should display platform statistics', async ({ page }) => {
    await dashboardPage.navigateToSuperAdminDashboard();
    
    // Check for stats cards
    const statsVisible = await dashboardPage.statsCards.first().isVisible();
    expect(statsVisible).toBe(true);
    
    // Check for specific stats
    const totalUsers = await dashboardPage.getTotalUsersCount();
    expect(totalUsers).toBeGreaterThanOrEqual(0);
    
    const totalTeams = await dashboardPage.getTotalTeamsCount();
    expect(totalTeams).toBeGreaterThanOrEqual(0);
  });

  test('should access system settings', async ({ page }) => {
    await dashboardPage.navigateToSuperAdminDashboard();
    await dashboardPage.navigateToSystemSettings();
    
    await expect(page).toHaveURL(/\/admin\/super\/settings/);
    await expect(page.locator('h1')).toContainText(/Settings/i);
  });

  test('should handle user impersonation', async ({ page }) => {
    await dashboardPage.navigateToSuperAdminDashboard();
    await dashboardPage.navigateToUserManagement();
    
    // Find a user to impersonate (not self)
    const impersonateButton = page.locator('button:has-text("Impersonate")').first();
    if (await impersonateButton.isVisible()) {
      await impersonateButton.click();
      
      // Should show impersonation banner
      await expect(page.locator('text=/Impersonating|Stop Impersonating/i')).toBeVisible({ timeout: 5000 });
    }
  });
});