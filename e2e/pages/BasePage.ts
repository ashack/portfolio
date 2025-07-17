import { Page, Locator } from '@playwright/test';

export class BasePage {
  readonly page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  // Common navigation elements
  get navBar() {
    return this.page.locator('[data-testid="navbar"]');
  }

  get userMenu() {
    return this.page.locator('[data-testid="user-menu"], button:has-text("undefined"), button:has(img[alt*="avatar"])').first();
  }

  get sideBar() {
    return this.page.locator('[data-testid="sidebar"]');
  }

  get flashMessages() {
    // Rails renders flash messages with role="alert" for errors and notices
    return this.page.locator('[role="alert"]');
  }

  get loadingSpinner() {
    return this.page.locator('[data-testid="loading-spinner"]');
  }

  // Common actions
  async navigate(path: string) {
    await this.page.goto(path);
    await this.waitForPageLoad();
  }

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  async waitForFlashMessage(text?: string) {
    if (text) {
      await this.flashMessages.filter({ hasText: text }).waitFor();
    } else {
      await this.flashMessages.waitFor();
    }
  }

  async getFlashMessageText(): Promise<string> {
    return await this.flashMessages.textContent() || '';
  }

  async getErrorMessage(): Promise<string | null> {
    // Check for flash alert messages (Rails flash[:alert])
    const flashAlert = await this.page.locator('[role="alert"]').first();
    if (await flashAlert.isVisible()) {
      const text = await flashAlert.textContent();
      return text ? text.trim() : null;
    }
    
    // Check for Devise error messages in the form
    const deviseError = await this.page.locator('.bg-red-50').first();
    if (await deviseError.isVisible()) {
      const text = await deviseError.textContent();
      return text ? text.trim() : null;
    }
    
    return null;
  }

  async dismissFlashMessage() {
    const closeButton = this.flashMessages.locator('[data-testid="flash-close"]');
    if (await closeButton.isVisible()) {
      await closeButton.click();
    }
  }

  async clickUserMenu() {
    await this.userMenu.click();
  }

  async logout() {
    // Try to find and click logout link
    const logoutLink = this.page.locator('a[href*="/users/sign_out"]').first();
    
    if (await logoutLink.isVisible()) {
      // Direct logout link visible
      await logoutLink.click();
    } else {
      // Try user menu first
      const userMenuButton = await this.page.locator('[data-testid="user-menu"], button:has-text("Account"), .relative button').first();
      if (await userMenuButton.isVisible()) {
        await userMenuButton.click();
        await this.page.waitForTimeout(500); // Wait for dropdown
        await this.page.locator('a[href*="/users/sign_out"]').click();
      } else {
        // Fallback to direct navigation
        await this.page.goto('/users/sign_out');
      }
    }
  }

  async navigateToProfile() {
    await this.clickUserMenu();
    await this.page.click('[data-testid="profile-link"]');
  }

  async navigateToBilling() {
    await this.clickUserMenu();
    await this.page.click('[data-testid="billing-link"]');
  }

  // Sidebar navigation helpers
  async clickSidebarLink(linkText: string) {
    await this.sideBar.locator(`text="${linkText}"`).click();
  }

  async isSidebarLinkActive(linkText: string): Promise<boolean> {
    const link = this.sideBar.locator(`text="${linkText}"`);
    const classes = await link.getAttribute('class') || '';
    return classes.includes('active') || classes.includes('bg-gray-900');
  }

  // Form helpers
  async fillForm(fields: Record<string, string>) {
    for (const [field, value] of Object.entries(fields)) {
      const input = this.page.locator(`[name="${field}"], [data-testid="${field}"]`);
      await input.fill(value);
    }
  }

  async selectOption(selector: string, value: string) {
    await this.page.selectOption(selector, value);
  }

  async checkCheckbox(selector: string) {
    const checkbox = this.page.locator(selector);
    if (!(await checkbox.isChecked())) {
      await checkbox.check();
    }
  }

  async uncheckCheckbox(selector: string) {
    const checkbox = this.page.locator(selector);
    if (await checkbox.isChecked()) {
      await checkbox.uncheck();
    }
  }

  // Validation helpers
  async hasErrorMessage(field: string, message?: string): Promise<boolean> {
    const errorSelector = `[data-testid="${field}-error"], .field_with_errors:has([name="${field}"]) + .error`;
    const error = this.page.locator(errorSelector);
    
    if (!(await error.isVisible())) {
      return false;
    }

    if (message) {
      const text = await error.textContent();
      return text?.includes(message) || false;
    }

    return true;
  }

  async getErrorMessages(): Promise<string[]> {
    const errors = await this.page.locator('.error, [data-testid*="-error"]').allTextContents();
    return errors.filter(text => text.trim() !== '');
  }

  // Waiting helpers
  async waitForURL(urlPattern: string | RegExp) {
    await this.page.waitForURL(urlPattern);
  }

  async waitForElement(selector: string) {
    await this.page.locator(selector).waitFor();
  }

  async waitForElementToDisappear(selector: string) {
    await this.page.locator(selector).waitFor({ state: 'hidden' });
  }

  // Screenshot helpers
  async takeScreenshot(name: string) {
    await this.page.screenshot({ 
      path: `test-results/screenshots/${name}.png`,
      fullPage: true 
    });
  }

  // Mobile helpers
  async openMobileMenu() {
    const mobileMenuButton = this.page.locator('[data-testid="mobile-menu-button"]');
    if (await mobileMenuButton.isVisible()) {
      await mobileMenuButton.click();
    }
  }

  async closeMobileMenu() {
    const mobileMenuClose = this.page.locator('[data-testid="mobile-menu-close"]');
    if (await mobileMenuClose.isVisible()) {
      await mobileMenuClose.click();
    }
  }

  // Utility methods
  async getPageTitle(): Promise<string> {
    return await this.page.title();
  }

  async getCurrentURL(): Promise<string> {
    return this.page.url();
  }

  async reload() {
    await this.page.reload();
  }

  async goBack() {
    await this.page.goBack();
  }

  async goForward() {
    await this.page.goForward();
  }
}