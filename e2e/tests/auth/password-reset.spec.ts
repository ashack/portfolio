import { test, expect } from '@playwright/test';
import { LoginPage } from '@pages/index';
import { testUsers } from '@fixtures/index';

test.describe('Password Reset Flow', () => {
  let loginPage: LoginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.navigate();
  });

  test('should navigate to password reset page', async ({ page }) => {
    await loginPage.clickForgotPassword();
    
    // Should be on password reset page
    await expect(page).toHaveURL(/\/users\/password\/new/);
    
    // Should show password reset form
    await expect(page.locator('h2')).toContainText('Forgot your password?');
    await expect(page.locator('[name="user[email]"]')).toBeVisible();
    await expect(page.locator('[type="submit"]')).toBeVisible();
  });

  test('should send password reset instructions for valid email', async ({ page }) => {
    await loginPage.clickForgotPassword();
    
    // Fill in email
    await page.fill('[name="user[email]"]', testUsers.directUser.email);
    await page.click('[type="submit"]');
    
    // Should redirect to login page with success message
    await expect(page).toHaveURL(/\/users\/sign_in/);
    
    const flashMessage = await loginPage.getFlashMessageText();
    expect(flashMessage).toContain('You will receive an email with instructions');
  });

  test('should show error for non-existent email', async ({ page }) => {
    await loginPage.clickForgotPassword();
    
    // Fill in non-existent email
    await page.fill('[name="user[email]"]', 'nonexistent@example.com');
    await page.click('[type="submit"]');
    
    // Should show error
    const errorElement = page.locator('.alert-danger, [data-testid="flash-message"].error');
    await expect(errorElement).toBeVisible();
    
    const errorText = await errorElement.textContent();
    expect(errorText).toContain('Email not found');
  });

  test('should validate email format', async ({ page }) => {
    await loginPage.clickForgotPassword();
    
    // Fill in invalid email
    await page.fill('[name="user[email]"]', 'invalid-email');
    await page.click('[type="submit"]');
    
    // Should show validation error
    const hasError = await page.locator('.field_with_errors:has([name="user[email]"])').isVisible();
    expect(hasError).toBe(true);
  });

  test('should handle empty email submission', async ({ page }) => {
    await loginPage.clickForgotPassword();
    
    // Submit without filling email
    await page.click('[type="submit"]');
    
    // Should show validation error
    const errorVisible = await page.locator('.error, [data-testid="email-error"]').isVisible();
    expect(errorVisible).toBe(true);
  });

  test('should navigate back to login from password reset', async ({ page }) => {
    await loginPage.clickForgotPassword();
    
    // Click back to login link
    const loginLink = page.locator('a[href*="/users/sign_in"]');
    await loginLink.click();
    
    // Should be back on login page
    await expect(page).toHaveURL(/\/users\/sign_in/);
    await expect(loginPage.loginButton).toBeVisible();
  });

  test.describe('Password Reset Token Flow', () => {
    test.skip('should reset password with valid token', async ({ page }) => {
      // This test requires intercepting email or having a valid reset token
      // Typically handled through API testing or with email interception
    });

    test.skip('should show error for invalid reset token', async ({ page }) => {
      // Navigate to reset page with invalid token
      await page.goto('/users/password/edit?reset_password_token=invalid_token');
      
      // Fill in new password
      await page.fill('[name="user[password]"]', 'NewPassword123!');
      await page.fill('[name="user[password_confirmation]"]', 'NewPassword123!');
      await page.click('[type="submit"]');
      
      // Should show error about invalid token
      const errorElement = page.locator('.alert-danger, [data-testid="flash-message"].error');
      await expect(errorElement).toBeVisible();
      
      const errorText = await errorElement.textContent();
      expect(errorText).toContain('token is invalid');
    });

    test.skip('should show error for expired reset token', async ({ page }) => {
      // This test requires an expired token
      // Typically handled through API testing
    });
  });
});