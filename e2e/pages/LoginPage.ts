import { Page, expect } from '@playwright/test';
import { BasePage } from './BasePage';

export class LoginPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  // Locators - Updated with data-testid selectors
  get emailInput() {
    return this.page.locator('[data-testid="login-email"]');
  }

  get passwordInput() {
    return this.page.locator('[data-testid="login-password"]');
  }

  get rememberMeCheckbox() {
    return this.page.locator('[data-testid="login-remember-me"]');
  }

  get loginButton() {
    return this.page.locator('[data-testid="login-submit"]');
  }

  get forgotPasswordLink() {
    return this.page.locator('[data-testid="login-forgot-password"]');
  }

  get signUpLink() {
    return this.page.locator('[data-testid="login-signup-link"]');
  }

  get resendConfirmationLink() {
    return this.page.locator('a[href*="confirmation/new"]');
  }

  get resendUnlockLink() {
    return this.page.locator('a[href*="unlock/new"]');
  }

  // Form error locators
  get emailError() {
    return this.page.locator('.field_with_errors input[name="user[email]"]');
  }

  get passwordError() {
    return this.page.locator('.field_with_errors input[name="user[password]"]');
  }

  // Security-related locators
  get csrfToken() {
    return this.page.locator('meta[name="csrf-token"]');
  }

  get formAuthenticityToken() {
    return this.page.locator('input[name="authenticity_token"]');
  }

  // Actions
  async navigate() {
    await super.navigate('/users/sign_in');
  }

  async login(email: string, password: string, rememberMe: boolean = false) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    
    if (rememberMe) {
      await this.rememberMeCheckbox.check();
    }
    
    await this.loginButton.click();
    await this.waitForPageLoad();
  }

  async loginAndExpectError(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
    
    // Wait for error message but stay on login page
    // Rails renders flash messages with role="alert"
    await this.page.waitForSelector('[role="alert"]');
  }

  async clickForgotPassword() {
    await this.forgotPasswordLink.click();
  }

  async clickSignUp() {
    await this.signUpLink.click();
  }

  async clickResendConfirmation() {
    await this.resendConfirmationLink.click();
  }

  async clickResendUnlock() {
    await this.resendUnlockLink.click();
  }

  // Validation helpers
  async hasLoginError(): Promise<boolean> {
    return await this.flashMessages.isVisible();
  }

  async getLoginErrorMessage(): Promise<string> {
    return await this.getFlashMessageText();
  }

  async isEmailFieldInvalid(): Promise<boolean> {
    return await this.hasErrorMessage('email');
  }

  async isPasswordFieldInvalid(): Promise<boolean> {
    return await this.hasErrorMessage('password');
  }

  // State checks
  async isOnLoginPage(): Promise<boolean> {
    const url = await this.getCurrentURL();
    return url.includes('/users/sign_in');
  }

  async isLoggedIn(): Promise<boolean> {
    // Check if user menu is visible (indicates logged in state)
    return await this.userMenu.isVisible();
  }

  async isRememberMeChecked(): Promise<boolean> {
    return await this.rememberMeCheckbox.isChecked();
  }

  // Security checks
  async hasCSRFToken(): Promise<boolean> {
    try {
      // Wait for the meta tag to be present
      await this.csrfToken.waitFor({ state: 'attached', timeout: 5000 });
      const token = await this.csrfToken.getAttribute('content');
      return token !== null && token.length > 0;
    } catch (error) {
      // Meta tag not found
      return false;
    }
  }

  async hasAuthenticityToken(): Promise<boolean> {
    try {
      // Wait for the form token to be present
      await this.formAuthenticityToken.waitFor({ state: 'attached', timeout: 5000 });
      const token = await this.formAuthenticityToken.getAttribute('value');
      return token !== null && token.length > 0;
    } catch (error) {
      // Form token not found
      return false;
    }
  }

  async getSecurityHeaders(): Promise<Record<string, string>> {
    const response = await this.page.request.get('/users/sign_in');
    return response.headers();
  }

  // Accessibility helpers
  async checkKeyboardNavigation(): Promise<boolean> {
    // Tab through form elements
    await this.page.keyboard.press('Tab'); // Should focus email
    const emailFocused = await this.emailInput.evaluate(el => el === document.activeElement);
    
    await this.page.keyboard.press('Tab'); // Should focus password
    const passwordFocused = await this.passwordInput.evaluate(el => el === document.activeElement);
    
    await this.page.keyboard.press('Tab'); // Should focus remember me
    const rememberFocused = await this.rememberMeCheckbox.evaluate(el => el === document.activeElement);
    
    return emailFocused && passwordFocused && rememberFocused;
  }

  async getAriaLabels(): Promise<Record<string, string | null>> {
    return {
      email: await this.emailInput.getAttribute('aria-label'),
      password: await this.passwordInput.getAttribute('aria-label'),
      rememberMe: await this.rememberMeCheckbox.getAttribute('aria-label'),
      submit: await this.loginButton.getAttribute('aria-label')
    };
  }

  // Performance helpers
  async measureLoginTime(email: string, password: string): Promise<number> {
    const startTime = Date.now();
    await this.login(email, password);
    const endTime = Date.now();
    return endTime - startTime;
  }

  // Advanced interaction methods
  async loginWithKeyboard(email: string, password: string): Promise<void> {
    await this.emailInput.focus();
    await this.page.keyboard.type(email);
    await this.page.keyboard.press('Tab');
    await this.page.keyboard.type(password);
    await this.page.keyboard.press('Enter');
    await this.waitForPageLoad();
  }

  async attemptSQLInjection(injectionString: string): Promise<void> {
    await this.emailInput.fill(injectionString);
    await this.passwordInput.fill("password");
    await this.loginButton.click();
  }

  async attemptXSS(xssPayload: string): Promise<void> {
    await this.emailInput.fill(xssPayload);
    await this.passwordInput.fill("password");
    await this.loginButton.click();
  }

  // Mobile-specific methods
  async tapLogin(): Promise<void> {
    await this.loginButton.tap();
  }

  async swipeToRememberMe(): Promise<void> {
    const rememberMeBox = await this.rememberMeCheckbox.boundingBox();
    if (rememberMeBox) {
      await this.page.mouse.move(rememberMeBox.x, rememberMeBox.y - 100);
      await this.page.mouse.down();
      await this.page.mouse.move(rememberMeBox.x, rememberMeBox.y);
      await this.page.mouse.up();
    }
  }

  // Visual regression helpers
  async takeLoginFormScreenshot(name: string): Promise<void> {
    const loginForm = this.page.locator('.bg-white.py-8.px-4.shadow');
    await loginForm.screenshot({ path: `screenshots/login-${name}.png` });
  }

  async compareWithBaseline(baselinePath: string): Promise<boolean> {
    // This would integrate with visual regression tools
    // For now, just return true as placeholder
    return true;
  }
}