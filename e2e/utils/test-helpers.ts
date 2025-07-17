import { Page, expect } from '@playwright/test';
import { faker } from '@faker-js/faker';

// Generate unique test data
export function generateTestEmail(): string {
  return `test_${Date.now()}_${faker.string.alphanumeric(6)}@example.com`;
}

export function generateTestName(): string {
  return faker.person.fullName();
}

export function generateTestTeamName(): string {
  return `Test Team ${faker.company.name()} ${Date.now()}`;
}

export function generateTestPassword(): string {
  return `Password${faker.number.int({ min: 100, max: 999 })}!`;
}

// Wait helpers
export async function waitForToast(page: Page, text?: string) {
  const toast = page.locator('[data-testid="toast"], .toast, [role="alert"]');
  
  if (text) {
    await expect(toast.filter({ hasText: text })).toBeVisible();
  } else {
    await expect(toast).toBeVisible();
  }
}

export async function waitForModal(page: Page, title?: string) {
  const modal = page.locator('[data-testid="modal"], [role="dialog"], .modal');
  await expect(modal).toBeVisible();
  
  if (title) {
    const modalTitle = modal.locator('h2, h3, [data-testid="modal-title"]');
    await expect(modalTitle).toHaveText(title);
  }
}

export async function closeModal(page: Page) {
  const closeButton = page.locator('[data-testid="modal-close"], [aria-label="Close"]');
  if (await closeButton.isVisible()) {
    await closeButton.click();
  } else {
    // Try escape key
    await page.keyboard.press('Escape');
  }
  
  // Wait for modal to disappear
  await expect(page.locator('[data-testid="modal"], [role="dialog"]')).toBeHidden();
}

// Form helpers
export async function fillAndSubmitForm(page: Page, formData: Record<string, string>) {
  for (const [field, value] of Object.entries(formData)) {
    const input = page.locator(`[name="${field}"], [data-testid="${field}"]`);
    await input.fill(value);
  }
  
  await page.locator('[type="submit"]').click();
}

export async function selectRadioOption(page: Page, name: string, value: string) {
  await page.locator(`input[name="${name}"][value="${value}"]`).check();
}

// Validation helpers
export async function expectFieldError(page: Page, field: string, errorText?: string) {
  const errorSelector = `[data-testid="${field}-error"], .field_with_errors:has([name="${field}"]) + .error`;
  const error = page.locator(errorSelector);
  
  await expect(error).toBeVisible();
  
  if (errorText) {
    await expect(error).toContainText(errorText);
  }
}

export async function expectNoFieldErrors(page: Page) {
  const errors = page.locator('.field_with_errors, [data-testid*="-error"]');
  await expect(errors).toHaveCount(0);
}

// Table helpers
export async function getTableRowCount(page: Page, tableSelector: string = 'table'): Promise<number> {
  const rows = page.locator(`${tableSelector} tbody tr`);
  return await rows.count();
}

export async function findTableRow(page: Page, text: string, tableSelector: string = 'table') {
  return page.locator(`${tableSelector} tbody tr`).filter({ hasText: text });
}

export async function clickTableAction(page: Page, rowText: string, actionText: string) {
  const row = await findTableRow(page, rowText);
  await row.locator(`button:has-text("${actionText}"), a:has-text("${actionText}")`).click();
}

// Pagination helpers
export async function goToNextPage(page: Page) {
  await page.locator('[data-testid="next-page"], a:has-text("Next")').click();
}

export async function goToPreviousPage(page: Page) {
  await page.locator('[data-testid="prev-page"], a:has-text("Previous")').click();
}

export async function goToPage(page: Page, pageNumber: number) {
  await page.locator(`[data-testid="page-${pageNumber}"], a:has-text("${pageNumber}")`).click();
}

// Date helpers
export function formatDate(date: Date): string {
  return date.toISOString().split('T')[0];
}

export function formatDateTime(date: Date): string {
  return date.toISOString().slice(0, 16);
}

// URL helpers
export async function expectURL(page: Page, pattern: string | RegExp) {
  await expect(page).toHaveURL(pattern);
}

export async function getQueryParam(page: Page, param: string): Promise<string | null> {
  const url = new URL(page.url());
  return url.searchParams.get(param);
}

// Local storage helpers
export async function setLocalStorage(page: Page, key: string, value: string) {
  await page.evaluate(([k, v]) => {
    localStorage.setItem(k, v);
  }, [key, value]);
}

export async function getLocalStorage(page: Page, key: string): Promise<string | null> {
  return await page.evaluate((k) => localStorage.getItem(k), key);
}

export async function clearLocalStorage(page: Page) {
  await page.evaluate(() => localStorage.clear());
}

// Session storage helpers
export async function setSessionStorage(page: Page, key: string, value: string) {
  await page.evaluate(([k, v]) => {
    sessionStorage.setItem(k, v);
  }, [key, value]);
}

export async function getSessionStorage(page: Page, key: string): Promise<string | null> {
  return await page.evaluate((k) => sessionStorage.getItem(k), key);
}

// Cookie helpers
export async function getCookie(page: Page, name: string) {
  const cookies = await page.context().cookies();
  return cookies.find(cookie => cookie.name === name);
}

export async function setCookie(page: Page, name: string, value: string) {
  await page.context().addCookies([{
    name,
    value,
    domain: new URL(page.url()).hostname,
    path: '/'
  }]);
}

// API helpers
export async function makeAPIRequest(page: Page, method: string, endpoint: string, data?: any) {
  const response = await page.request[method.toLowerCase()](endpoint, {
    data,
    headers: {
      'X-CSRF-Token': await getCSRFToken(page),
      'Accept': 'application/json'
    }
  });
  
  return {
    status: response.status(),
    data: await response.json().catch(() => null),
    headers: response.headers()
  };
}

export async function getCSRFToken(page: Page): Promise<string> {
  const token = await page.locator('meta[name="csrf-token"]').getAttribute('content');
  return token || '';
}

// Debug helpers
export async function pauseTest(page: Page, message?: string) {
  if (message) {
    console.log(`⏸️  Paused: ${message}`);
  }
  await page.pause();
}

export async function logTestInfo(message: string, data?: any) {
  console.log(`ℹ️  ${message}`);
  if (data) {
    console.log(JSON.stringify(data, null, 2));
  }
}

// Retry helpers
export async function retryOperation<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  delay: number = 1000
): Promise<T> {
  let lastError: Error;
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (error) {
      lastError = error as Error;
      if (i < maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }
  
  throw lastError!;
}

// Network helpers
export async function waitForAPIResponse(page: Page, urlPattern: string | RegExp) {
  return page.waitForResponse(response => {
    const url = response.url();
    return typeof urlPattern === 'string' ? url.includes(urlPattern) : urlPattern.test(url);
  });
}

export async function mockAPIResponse(page: Page, urlPattern: string | RegExp, response: any) {
  await page.route(urlPattern, route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(response)
    });
  });
}

// Accessibility helpers
export async function checkAccessibility(page: Page) {
  // Basic accessibility checks
  const results = await page.evaluate(() => {
    const issues = [];
    
    // Check for alt text on images
    const images = document.querySelectorAll('img');
    images.forEach(img => {
      if (!img.alt && !img.getAttribute('role')) {
        issues.push(`Image missing alt text: ${img.src}`);
      }
    });
    
    // Check for form labels
    const inputs = document.querySelectorAll('input, select, textarea');
    inputs.forEach(input => {
      const id = input.id;
      if (id && !document.querySelector(`label[for="${id}"]`)) {
        issues.push(`Input missing label: ${id}`);
      }
    });
    
    return issues;
  });
  
  return results;
}