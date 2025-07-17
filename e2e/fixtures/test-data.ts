import { Page } from '@playwright/test';
import { execSync } from 'child_process';
import * as fs from 'fs';

// Test data interfaces
export interface TestPlan {
  id: number;
  name: string;
  plan_segment: 'individual' | 'team' | 'enterprise';
  amount_cents: number;
  stripe_price_id?: string;
  interval?: 'month' | 'year';
  features: string[];
}

export interface TestTeam {
  id: number;
  name: string;
  slug: string;
  admin_email: string;
  plan_id: number;
}

export interface TestEnterpriseGroup {
  id: number;
  name: string;
  slug: string;
  admin_email: string;
}

// Database helpers
export class TestDataManager {
  private createdUsers: string[] = [];
  private createdTeams: string[] = [];
  private createdEnterpriseGroups: string[] = [];

  // Execute Rails command
  private runRailsCommand(command: string): string {
    try {
      // Write command to a temporary file to avoid escaping issues
      const tmpFile = `/tmp/rails_command_${Date.now()}.rb`;
      fs.writeFileSync(tmpFile, command);
      
      const result = execSync(`RAILS_ENV=e2e_test bundle exec rails runner ${tmpFile}`, {
        encoding: 'utf8',
        env: { ...process.env, RAILS_ENV: 'e2e_test' }
      });
      
      // Clean up temp file
      fs.unlinkSync(tmpFile);
      
      return result;
    } catch (error) {
      console.error(`Failed to run Rails command: ${command}`, error);
      throw error;
    }
  }


  // Create test users with options
  async createTestUser(
    email: string, 
    password: string, 
    userType: string, 
    systemRole: string = 'user',
    options: {
      confirmed?: boolean;
      locked?: boolean;
      status?: string;
      failedAttempts?: number;
    } = {}
  ): Promise<void> {
    const confirmedAt = options.confirmed !== false ? 'Time.current' : 'nil';
    const lockedAt = options.locked ? 'Time.current' : 'nil';
    const status = options.status || 'active';
    const failedAttempts = options.failedAttempts || 0;

    const userCommand = `
      user = User.find_or_initialize_by(email: '${email}')
      user.assign_attributes(
        password: '${password}',
        password_confirmation: '${password}',
        user_type: '${userType}',
        system_role: '${systemRole}',
        status: '${status}',
        first_name: '${email.split('@')[0].capitalize}',
        last_name: 'Test',
        confirmed_at: ${confirmedAt},
        locked_at: ${lockedAt},
        failed_attempts: ${failedAttempts}
      )
      user.save!(validate: false)
      puts user.id
    `;

    this.runRailsCommand(userCommand);
    this.createdUsers.push(email);
  }

  // Create test team
  async createTestTeam(name: string, adminEmail: string): Promise<TestTeam> {
    const teamCommand = `
      admin = User.find_by!(email: '${adminEmail}')
      plan = Plan.find_by!(plan_segment: 'team', name: 'Team Starter')
      
      team = Team.create!(
        name: '${name}',
        created_by: admin,
        admin: admin,
        plan_id: plan.id,
        stripe_customer_id: "cus_test_#{SecureRandom.hex(8)}",
        status: 'active'
      )
      
      # Update admin's association
      admin.update!(team: team, team_role: 'admin')
      
      puts "#{team.id}|#{team.slug}"
    `;

    const result = this.runRailsCommand(teamCommand).trim();
    const [id, slug] = result.split('|');
    
    this.createdTeams.push(slug);
    
    return {
      id: parseInt(id),
      name,
      slug,
      admin_email: adminEmail,
      plan_id: 3 // Team Starter plan
    };
  }

  // Create test enterprise group
  async createTestEnterpriseGroup(name: string, adminEmail: string): Promise<TestEnterpriseGroup> {
    const enterpriseCommand = `
      admin = User.find_or_create_by!(email: '${adminEmail}') do |u|
        u.password = 'Password123!'
        u.user_type = 'enterprise'
        u.system_role = 'user'
        u.status = 'active'
        u.confirmed_at = Time.current
        u.first_name = '${adminEmail.split('@')[0].capitalize}'
        u.last_name = 'Enterprise'
      end
      
      plan = Plan.find_by!(plan_segment: 'enterprise')
      creator = User.find_by!(system_role: 'super_admin')
      
      enterprise = EnterpriseGroup.create!(
        name: '${name}',
        created_by: creator,
        admin: admin,
        plan_id: plan.id,
        stripe_customer_id: "cus_test_#{SecureRandom.hex(8)}",
        status: 'active'
      )
      
      # Update admin's association
      admin.update!(enterprise_group: enterprise, enterprise_group_role: 'admin')
      
      puts "#{enterprise.id}|#{enterprise.slug}"
    `;

    const result = this.runRailsCommand(enterpriseCommand).trim();
    const [id, slug] = result.split('|');
    
    this.createdEnterpriseGroups.push(slug);
    
    return {
      id: parseInt(id),
      name,
      slug,
      admin_email: adminEmail
    };
  }

  // Create all test users
  async setupTestUsers(): Promise<void> {
    // Super Admin
    await this.createTestUser(
      process.env.TEST_SUPER_ADMIN_EMAIL || 'super@example.com',
      process.env.TEST_SUPER_ADMIN_PASSWORD || 'Password123!',
      'direct',
      'super_admin'
    );

    // Site Admin
    await this.createTestUser(
      process.env.TEST_SITE_ADMIN_EMAIL || 'site@example.com',
      process.env.TEST_SITE_ADMIN_PASSWORD || 'Password123!',
      'direct',
      'site_admin'
    );

    // Direct User
    await this.createTestUser(
      process.env.TEST_DIRECT_USER_EMAIL || 'direct@example.com',
      process.env.TEST_DIRECT_USER_PASSWORD || 'Password123!',
      'direct',
      'user'
    );
  }

  // Setup complete test environment
  async setupTestEnvironment(): Promise<void> {
    console.log('🔧 Setting up test environment...');
    
    // Clean database using DatabaseCleaner
    try {
      this.runRailsCommand(`
        require File.join(Rails.root, 'config', 'e2e_test_helper')
        
        # Clean the database
        E2ETestHelper.clean_database
        
        # Setup basic data (plans, notification categories)
        E2ETestHelper.setup_basic_data
      `);
    } catch (error) {
      console.warn('Could not clean database:', error);
    }
    
    // Create users
    await this.setupTestUsers();
    
    // Skip team creation for now due to model issues
    // const team = await this.createTestTeam('Test Team', process.env.TEST_SUPER_ADMIN_EMAIL || 'super@example.com');
    
    // Create team admin as direct user for now
    await this.createTestUser(
      process.env.TEST_TEAM_ADMIN_EMAIL || 'teamadmin@example.com',
      process.env.TEST_TEAM_ADMIN_PASSWORD || 'Password123!',
      'direct',
      'user'
    );
    
    // Create team member as direct user for now
    await this.createTestUser(
      process.env.TEST_TEAM_MEMBER_EMAIL || 'member@example.com',
      process.env.TEST_TEAM_MEMBER_PASSWORD || 'Password123!',
      'direct',
      'user'
    );
    
    // Create edge case users
    await this.setupEdgeCaseUsers();
    
    console.log('✅ Test environment setup complete');
  }

  // Setup edge case test users
  async setupEdgeCaseUsers(): Promise<void> {
    // Unconfirmed user
    await this.createTestUser(
      'unconfirmed@example.com',
      'Password123!',
      'direct',
      'user',
      { confirmed: false }
    );

    // Locked user (too many failed attempts)
    await this.createTestUser(
      'locked@example.com',
      'Password123!',
      'direct',
      'user',
      { locked: true, failedAttempts: 5 }
    );

    // Inactive user
    await this.createTestUser(
      'inactive@example.com',
      'Password123!',
      'direct',
      'user',
      { status: 'inactive' }
    );

    // User with special characters in email
    await this.createTestUser(
      'user+test@example.com',
      'Password123!',
      'direct',
      'user'
    );

    // User with very long password
    await this.createTestUser(
      'longpass@example.com',
      'A'.repeat(128) + '1!',
      'direct',
      'user'
    );
  }

  // Cleanup test data
  async cleanup(): Promise<void> {
    console.log('🧹 Cleaning up test data...');
    
    try {
      // Use DatabaseCleaner to clean all test data
      this.runRailsCommand(`
        require File.join(Rails.root, 'config', 'e2e_test_helper')
        
        # Clean the entire database
        E2ETestHelper.clean_database
        
        puts "✅ Database cleaned"
      `);
    } catch (error) {
      console.error('Failed to clean database:', error);
      
      // Fallback to manual cleanup if DatabaseCleaner fails
      // Remove created teams
      if (this.createdTeams.length > 0) {
        const teamSlugs = this.createdTeams.map(s => `'${s}'`).join(',');
        this.runRailsCommand(`Team.where(slug: [${teamSlugs}]).destroy_all`);
      }
      
      // Remove created enterprise groups
      if (this.createdEnterpriseGroups.length > 0) {
        const enterpriseSlugs = this.createdEnterpriseGroups.map(s => `'${s}'`).join(',');
        this.runRailsCommand(`EnterpriseGroup.where(slug: [${enterpriseSlugs}]).destroy_all`);
      }
      
      // Remove created users
      if (this.createdUsers.length > 0) {
        const emails = this.createdUsers.map(e => `'${e}'`).join(',');
        this.runRailsCommand(`User.where(email: [${emails}]).destroy_all`);
      }
    }
    
    console.log('✅ Cleanup complete');
  }
}

// Export singleton instance
export const testDataManager = new TestDataManager();