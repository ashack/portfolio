import { test, expect } from '@playwright/test';

test.describe('Smoke Tests', () => {
  test('should load the home page', async ({ page }) => {
    await page.goto('/');
    
    // Check that the page loads
    await expect(page).toHaveTitle(/SaaS/i);
    
    // Check for common elements
    const navbar = page.locator('nav, [data-testid="navbar"]');
    await expect(navbar).toBeVisible();
    
    // Check for login link
    const loginLink = page.locator('a[href*="/users/sign_in"]');
    await expect(loginLink).toBeVisible();
  });

  test('should load the login page', async ({ page }) => {
    await page.goto('/users/sign_in');
    
    // Check for login form elements
    await expect(page.locator('#user_email, [name="user[email]"]')).toBeVisible();
    await expect(page.locator('#user_password, [name="user[password]"]')).toBeVisible();
    await expect(page.locator('[type="submit"]')).toBeVisible();
  });

  test('should load pricing page', async ({ page }) => {
    await page.goto('/pricing');
    
    // Check for pricing content
    await expect(page.locator('h1, h2').first()).toBeVisible();
    
    // Should have some plan information
    const pageContent = await page.textContent('body');
    expect(pageContent).toContain('plan');
  });
});