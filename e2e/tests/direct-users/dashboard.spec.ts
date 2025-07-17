import { test, expect } from '@playwright/test';
import { LoginPage, DashboardPage } from '@pages/index';
import { testUsers } from '@fixtures/index';

test.describe('Direct User Dashboard', () => {
  let loginPage: LoginPage;
  let dashboardPage: DashboardPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    dashboardPage = new DashboardPage(page);
    
    // Login as direct user
    await loginPage.navigate();
    await loginPage.login(testUsers.directUser.email, testUsers.directUser.password);
    
    // Should redirect to user dashboard
    await expect(page).toHaveURL(/\/dashboard|\/redirect_after_sign_in/);
  });

  test('should display user dashboard', async ({ page }) => {
    // Navigate to dashboard if not already there
    if (!page.url().includes('/dashboard')) {
      await dashboardPage.navigateToUserDashboard();
    }
    
    // Check dashboard type
    const dashboardType = await dashboardPage.getDashboardType();
    expect(dashboardType).toBe('direct_user');
    
    // Check for welcome message
    const welcomeText = await dashboardPage.getWelcomeText();
    expect(welcomeText).toMatch(/welcome|dashboard/i);
  });

  test('should navigate to profile management', async ({ page }) => {
    await dashboardPage.navigateToUserDashboard();
    
    // Click profile link in sidebar or menu
    const profileLink = page.locator('a:has-text("Profile")').first();
    await profileLink.click();
    
    await expect(page).toHaveURL(/\/profile|\/users\/profile/);
    await expect(page.locator('h1')).toContainText(/Profile/i);
  });

  test('should navigate to billing page', async ({ page }) => {
    await dashboardPage.navigateToUserDashboard();
    
    // Click billing link
    const billingLink = page.locator('a:has-text("Billing")').first();
    await billingLink.click();
    
    await expect(page).toHaveURL(/\/billing|\/users\/billing/);
    await expect(page.locator('h1')).toContainText(/Billing/i);
  });

  test('should show create team option for direct users', async ({ page }) => {
    await dashboardPage.navigateToUserDashboard();
    
    // Direct users can create teams
    const createTeamButton = page.locator('a:has-text("Create Team"), button:has-text("Create Team")').first();
    expect(await createTeamButton.isVisible()).toBe(true);
  });

  test('should access account settings', async ({ page }) => {
    await dashboardPage.navigateToUserDashboard();
    
    // Click settings link
    const settingsLink = page.locator('a:has-text("Settings")').first();
    await settingsLink.click();
    
    await expect(page).toHaveURL(/\/settings|\/users\/settings/);
    await expect(page.locator('h1')).toContainText(/Settings/i);
  });

  test('should display subscription information', async ({ page }) => {
    await dashboardPage.navigateToUserDashboard();
    
    // Navigate to subscription page
    const subscriptionLink = page.locator('a:has-text("Subscription")').first();
    if (await subscriptionLink.isVisible()) {
      await subscriptionLink.click();
      await expect(page).toHaveURL(/\/subscription/);
      
      // Should show current plan
      await expect(page.locator('text=/Free|Pro|Premium/i')).toBeVisible();
    }
  });

  test('should handle plan upgrade flow', async ({ page }) => {
    await dashboardPage.navigateToUserDashboard();
    
    // Look for upgrade button
    const upgradeButton = page.locator('a:has-text("Upgrade"), button:has-text("Upgrade")').first();
    if (await upgradeButton.isVisible()) {
      await upgradeButton.click();
      
      // Should navigate to plan selection or pricing
      await expect(page).toHaveURL(/\/pricing|\/plans|\/upgrade/);
    }
  });

  test('should logout successfully', async ({ page }) => {
    await dashboardPage.navigateToUserDashboard();
    await dashboardPage.logout();
    
    // Should redirect to login page
    await expect(page).toHaveURL(/\/users\/sign_in/);
  });
});