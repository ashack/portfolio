import { Page } from '@playwright/test';
import { BasePage } from './BasePage';

export class DashboardPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  // Common dashboard elements
  get welcomeMessage() {
    return this.page.locator('[data-testid="welcome-message"], h1');
  }

  get statsCards() {
    return this.page.locator('[data-testid="stats-card"]');
  }

  get quickActions() {
    return this.page.locator('[data-testid="quick-actions"]');
  }

  get recentActivity() {
    return this.page.locator('[data-testid="recent-activity"]');
  }

  // Navigation methods for different dashboard types
  async navigateToUserDashboard() {
    await super.navigate('/dashboard');
  }

  async navigateToTeamDashboard(teamSlug: string) {
    await super.navigate(`/teams/${teamSlug}`);
  }

  async navigateToTeamAdminDashboard(teamSlug: string) {
    await super.navigate(`/teams/${teamSlug}/admin`);
  }

  async navigateToSuperAdminDashboard() {
    await super.navigate('/admin/super');
  }

  async navigateToSiteAdminDashboard() {
    await super.navigate('/admin/site');
  }

  async navigateToEnterpriseDashboard(enterpriseSlug: string) {
    await super.navigate(`/enterprise/${enterpriseSlug}`);
  }

  // Common dashboard actions
  async getWelcomeText(): Promise<string> {
    return await this.welcomeMessage.textContent() || '';
  }

  async getStatValue(statName: string): Promise<string> {
    const stat = this.statsCards.filter({ hasText: statName });
    const value = await stat.locator('[data-testid="stat-value"]').textContent();
    return value || '';
  }

  async clickQuickAction(actionName: string) {
    await this.quickActions.locator(`text="${actionName}"`).click();
  }

  // Direct User Dashboard specific
  async navigateToCreateTeam() {
    await this.clickQuickAction('Create Team');
  }

  async navigateToUpgradePlan() {
    await this.clickQuickAction('Upgrade Plan');
  }

  // Team Admin Dashboard specific
  async navigateToInviteMembers() {
    await this.clickSidebarLink('Invitations');
  }

  async navigateToTeamSettings() {
    await this.clickSidebarLink('Settings');
  }

  async navigateToTeamBilling() {
    await this.clickSidebarLink('Billing');
  }

  async getTeamMemberCount(): Promise<number> {
    const countText = await this.getStatValue('Team Members');
    return parseInt(countText) || 0;
  }

  // Super Admin Dashboard specific
  async navigateToUserManagement() {
    await this.clickSidebarLink('Users');
  }

  async navigateToTeamManagement() {
    await this.clickSidebarLink('Teams');
  }

  async navigateToSystemSettings() {
    await this.clickSidebarLink('Settings');
  }

  async navigateToAnalytics() {
    await this.clickSidebarLink('Analytics');
  }

  async getTotalUsersCount(): Promise<number> {
    const countText = await this.getStatValue('Total Users');
    return parseInt(countText) || 0;
  }

  async getTotalTeamsCount(): Promise<number> {
    const countText = await this.getStatValue('Total Teams');
    return parseInt(countText) || 0;
  }

  // Site Admin Dashboard specific
  async navigateToSupportTickets() {
    await this.clickSidebarLink('Support');
  }

  async navigateToActivityLogs() {
    await this.clickSidebarLink('Activity');
  }

  // State checks
  async isOnDashboard(): Promise<boolean> {
    const url = await this.getCurrentURL();
    return url.includes('dashboard') || url.includes('/admin/');
  }

  async getDashboardType(): Promise<string> {
    const url = await this.getCurrentURL();
    
    if (url.includes('/admin/super')) return 'super_admin';
    if (url.includes('/admin/site')) return 'site_admin';
    if (url.includes('/teams/') && url.includes('/admin')) return 'team_admin';
    if (url.includes('/teams/')) return 'team_member';
    if (url.includes('/enterprise/')) return 'enterprise';
    if (url.includes('/dashboard')) return 'direct_user';
    
    return 'unknown';
  }

  // Recent activity helpers
  async getRecentActivityItems(): Promise<string[]> {
    return await this.recentActivity.locator('li').allTextContents();
  }

  async hasRecentActivity(activityText: string): Promise<boolean> {
    const activities = await this.getRecentActivityItems();
    return activities.some(activity => activity.includes(activityText));
  }
}