import { test, expect } from '@playwright/test';

test.describe('Direct User Registration', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/users/sign_up');
  });

  test('should display registration form', async ({ page }) => {
    await expect(page.locator('h2')).toContainText(/Sign up|Create.*account/i);
    
    // Check for form fields
    await expect(page.locator('input[name="user[email]"]')).toBeVisible();
    await expect(page.locator('input[name="user[password]"]')).toBeVisible();
    await expect(page.locator('input[name="user[password_confirmation]"]')).toBeVisible();
  });

  test('should register new direct user with individual plan', async ({ page }) => {
    const timestamp = Date.now();
    const email = `testuser${timestamp}@example.com`;
    const password = 'Password123!';
    
    // Fill registration form
    await page.fill('input[name="user[email]"]', email);
    await page.fill('input[name="user[password]"]', password);
    await page.fill('input[name="user[password_confirmation]"]', password);
    
    // Select individual plan if visible
    const individualPlan = page.locator('[data-plan-type="individual"]').first();
    if (await individualPlan.isVisible()) {
      await individualPlan.click();
    }
    
    // Submit form
    await page.click('button[type="submit"], input[type="submit"]');
    
    // Should redirect to dashboard or show confirmation
    await expect(page).toHaveURL(/\/dashboard|\/users\/sign_in/, { timeout: 10000 });
    
    // Check for success message
    const successMessage = page.locator('[role="alert"]').filter({ hasText: /welcome|confirm|success/i });
    if (await successMessage.isVisible()) {
      expect(await successMessage.textContent()).toMatch(/welcome|confirm|success/i);
    }
  });

  test('should show validation errors for invalid input', async ({ page }) => {
    // Submit empty form
    await page.click('button[type="submit"], input[type="submit"]');
    
    // Should show validation errors
    await expect(page.locator('text=/can\'t be blank|required/i')).toBeVisible();
  });

  test('should validate email format', async ({ page }) => {
    await page.fill('input[name="user[email]"]', 'invalid-email');
    await page.fill('input[name="user[password]"]', 'Password123!');
    await page.fill('input[name="user[password_confirmation]"]', 'Password123!');
    
    await page.click('button[type="submit"], input[type="submit"]');
    
    // Should show email validation error
    await expect(page.locator('text=/invalid|email/i')).toBeVisible();
  });

  test('should validate password confirmation', async ({ page }) => {
    const timestamp = Date.now();
    const email = `testuser${timestamp}@example.com`;
    
    await page.fill('input[name="user[email]"]', email);
    await page.fill('input[name="user[password]"]', 'Password123!');
    await page.fill('input[name="user[password_confirmation]"]', 'DifferentPassword123!');
    
    await page.click('button[type="submit"], input[type="submit"]');
    
    // Should show password mismatch error
    await expect(page.locator('text=/match|confirm/i')).toBeVisible();
  });

  test('should navigate to login page', async ({ page }) => {
    const loginLink = page.locator('a:has-text("Sign in"), a:has-text("Log in")').first();
    await loginLink.click();
    
    await expect(page).toHaveURL(/\/users\/sign_in/);
  });

  test('should allow plan selection during registration', async ({ page }) => {
    // Check if plan selection is visible
    const planOptions = page.locator('[data-plan-type]');
    if (await planOptions.count() > 0) {
      // Select team plan
      await page.locator('[data-plan-type="team"]').click();
      
      // Team plan should be selected
      const selectedPlan = page.locator('[data-plan-type="team"]');
      const classes = await selectedPlan.getAttribute('class');
      expect(classes).toMatch(/selected|active|ring/);
    }
  });
});