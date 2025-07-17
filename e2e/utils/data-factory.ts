import { faker } from '@faker-js/faker';

export interface TestUserData {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  fullName: string;
}

export interface TestTeamData {
  name: string;
  slug: string;
  description: string;
  planType: 'starter' | 'pro' | 'enterprise';
}

export interface TestEnterpriseData {
  name: string;
  slug: string;
  domain: string;
  employeeCount: number;
}

export interface TestInvitationData {
  email: string;
  role: string;
  message?: string;
}

export class DataFactory {
  // User data generation
  static createUser(overrides?: Partial<TestUserData>): TestUserData {
    const firstName = faker.person.firstName();
    const lastName = faker.person.lastName();
    
    return {
      email: faker.internet.email({ firstName, lastName }).toLowerCase(),
      password: 'Password123!',
      firstName,
      lastName,
      fullName: `${firstName} ${lastName}`,
      ...overrides
    };
  }

  static createUniqueEmail(): string {
    return `test_${Date.now()}_${faker.string.alphanumeric(6)}@example.com`;
  }

  // Team data generation
  static createTeam(overrides?: Partial<TestTeamData>): TestTeamData {
    const name = faker.company.name();
    const slug = name.toLowerCase().replace(/[^a-z0-9]/g, '-').substring(0, 30);
    
    return {
      name,
      slug,
      description: faker.company.catchPhrase(),
      planType: 'starter',
      ...overrides
    };
  }

  static createTeamName(): string {
    return `${faker.company.name()} ${Date.now()}`;
  }

  // Enterprise data generation
  static createEnterprise(overrides?: Partial<TestEnterpriseData>): TestEnterpriseData {
    const name = `${faker.company.name()} Enterprise`;
    const slug = name.toLowerCase().replace(/[^a-z0-9]/g, '-').substring(0, 30);
    
    return {
      name,
      slug,
      domain: faker.internet.domainName(),
      employeeCount: faker.number.int({ min: 100, max: 5000 }),
      ...overrides
    };
  }

  // Invitation data generation
  static createInvitation(overrides?: Partial<TestInvitationData>): TestInvitationData {
    return {
      email: this.createUniqueEmail(),
      role: 'member',
      message: faker.lorem.sentence(),
      ...overrides
    };
  }

  static createBulkInvitations(count: number, role: string = 'member'): TestInvitationData[] {
    return Array.from({ length: count }, () => this.createInvitation({ role }));
  }

  // Plan data
  static getPlanData(planType: 'individual' | 'team') {
    if (planType === 'individual') {
      return {
        free: {
          name: 'Free',
          price: 0,
          features: ['Basic features', '1 user', 'Community support']
        },
        pro: {
          name: 'Pro',
          price: 19,
          features: ['All Free features', 'Priority support', 'Advanced analytics']
        },
        premium: {
          name: 'Premium',
          price: 49,
          features: ['All Pro features', 'Custom integrations', 'Dedicated support']
        }
      };
    } else {
      return {
        starter: {
          name: 'Starter',
          price: 49,
          users: 5,
          features: ['Up to 5 users', 'Team collaboration', 'Basic reporting']
        },
        pro: {
          name: 'Pro',
          price: 99,
          users: 15,
          features: ['Up to 15 users', 'Advanced features', 'Priority support']
        },
        enterprise: {
          name: 'Enterprise',
          price: 199,
          users: 100,
          features: ['Up to 100 users', 'Custom features', 'Dedicated support']
        }
      };
    }
  }

  // Credit card data (for Stripe test mode)
  static getCreditCardData(type: 'valid' | 'declined' | 'insufficient_funds' = 'valid') {
    const cards = {
      valid: {
        number: '4242424242424242',
        exp_month: '12',
        exp_year: (new Date().getFullYear() + 2).toString(),
        cvc: '123',
        zip: '10001'
      },
      declined: {
        number: '4000000000000002',
        exp_month: '12',
        exp_year: (new Date().getFullYear() + 2).toString(),
        cvc: '123',
        zip: '10001'
      },
      insufficient_funds: {
        number: '4000000000009995',
        exp_month: '12',
        exp_year: (new Date().getFullYear() + 2).toString(),
        cvc: '123',
        zip: '10001'
      }
    };
    
    return cards[type];
  }

  // Address data
  static createAddress() {
    return {
      street: faker.location.streetAddress(),
      city: faker.location.city(),
      state: faker.location.state({ abbreviated: true }),
      zip: faker.location.zipCode(),
      country: 'US'
    };
  }

  // Company data
  static createCompanyInfo() {
    return {
      name: faker.company.name(),
      website: faker.internet.url(),
      industry: faker.commerce.department(),
      size: faker.helpers.arrayElement(['1-10', '11-50', '51-200', '201-500', '500+']),
      description: faker.company.catchPhrase()
    };
  }

  // Random selection helpers
  static randomRole(userType: 'team' | 'enterprise' = 'team'): string {
    if (userType === 'team') {
      return faker.helpers.arrayElement(['admin', 'member']);
    } else {
      return faker.helpers.arrayElement(['admin', 'member', 'viewer']);
    }
  }

  static randomPlan(type: 'individual' | 'team' = 'individual'): string {
    if (type === 'individual') {
      return faker.helpers.arrayElement(['free', 'pro', 'premium']);
    } else {
      return faker.helpers.arrayElement(['starter', 'pro', 'enterprise']);
    }
  }

  // Date helpers
  static futureDate(days: number = 30): Date {
    return faker.date.future({ years: 0, refDate: new Date(Date.now() + days * 24 * 60 * 60 * 1000) });
  }

  static pastDate(days: number = 30): Date {
    return faker.date.past({ years: 0, refDate: new Date(Date.now() - days * 24 * 60 * 60 * 1000) });
  }

  static dateRange(startDays: number = 0, endDays: number = 30) {
    const start = new Date(Date.now() + startDays * 24 * 60 * 60 * 1000);
    const end = new Date(Date.now() + endDays * 24 * 60 * 60 * 1000);
    
    return {
      start: start.toISOString().split('T')[0],
      end: end.toISOString().split('T')[0]
    };
  }

  // Activity/Audit log data
  static createActivityLog() {
    const actions = [
      'user.login',
      'user.logout',
      'user.update_profile',
      'team.invite_member',
      'team.remove_member',
      'billing.update_subscription',
      'settings.update'
    ];
    
    return {
      action: faker.helpers.arrayElement(actions),
      timestamp: faker.date.recent(),
      ip_address: faker.internet.ip(),
      user_agent: faker.internet.userAgent(),
      details: {
        before: {},
        after: {}
      }
    };
  }

  // Notification data
  static createNotification() {
    const types = [
      'invitation_received',
      'team_member_joined',
      'subscription_updated',
      'payment_failed',
      'system_announcement'
    ];
    
    return {
      type: faker.helpers.arrayElement(types),
      title: faker.lorem.sentence(5),
      message: faker.lorem.paragraph(2),
      read: faker.datatype.boolean(),
      created_at: faker.date.recent()
    };
  }
}