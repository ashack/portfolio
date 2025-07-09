# Architecture Documentation

Welcome to the comprehensive architecture documentation for the SaaS Rails Starter Kit. This guide provides detailed technical information about the system design, implementation patterns, and architectural decisions.

> **Note**: For general documentation and getting started, see the [Main Documentation Hub](../README.md). This guide focuses specifically on architectural details.

## 📚 Documentation Structure

### Core Architecture
1. **[System Overview](01-system-overview.md)** - High-level architecture, technology stack, and core principles
2. **[User Architecture](02-user-architecture.md)** - Triple-track user system, registration flows, and user management
3. **[Database Design](03-database-design.md)** - Schema design, relationships, constraints, and data integrity
4. **[Authentication & Authorization](04-authentication.md)** - Devise configuration, Pundit policies, and security flows
5. **[Billing Architecture](05-billing-architecture.md)** - Stripe integration, subscription management, and payment processing
6. **[Frontend Architecture](06-frontend-architecture.md)** - UI framework, component system, and client-side patterns
7. **[API Design](07-api-design.md)** - RESTful API architecture and future GraphQL considerations

### Visual Documentation
- **[Diagrams](diagrams/)** - System diagrams, user flows, and entity relationships
  - [System Overview Diagram](diagrams/system-overview.md)
  - [User Flow Diagrams](diagrams/user-flows.md)
  - [Database ERD](diagrams/database-erd.md)

### Enterprise Architecture
- **Polymorphic Invitations**: Flexible system supporting both teams and enterprise groups
- **Purple-Themed UI**: Distinct visual identity for enterprise dashboards
- **Separate Namespace**: Complete `Enterprise::` namespace with dedicated controllers
- **Advanced Security**: Enterprise-specific rate limiting and audit logging
- **No Circular Dependencies**: Admin assignment via invitation flow

### Performance Architecture
- **Background Job Processing**: Asynchronous activity tracking with Redis caching
- **Query Optimization**: Eliminated N+1 queries with eager loading and query objects
- **Caching Strategy**: Model-level and fragment caching with automatic invalidation
- **Database Indexes**: 15+ optimized indexes for common query patterns
- **Pre-calculated Statistics**: Reduced database queries in views

### Database Architecture Updates
- **New Tables**: `enterprise_groups` for organization management
- **Polymorphic Support**: Updated `invitations` table with `invitable_type` and `invitable_id`
- **Enhanced Constraints**: User type constraints now include enterprise users
- **Notification System**: `noticed_events` and `noticed_notifications` tables

## 🏗️ System Architecture at a Glance

### Technology Stack
- **Backend**: Rails 8.0.2, Ruby 3.2.5
- **Database**: SQLite (development), PostgreSQL (production)
- **Frontend**: Tailwind CSS, Stimulus.js, Turbo, Phosphor Icons
- **Authentication**: Devise with 8 security modules
- **Authorization**: Pundit policy-based system
- **Payments**: Stripe via Pay gem
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache with Redis
- **Analytics**: Ahoy Matey
- **Security**: Rack::Attack rate limiting
- **Notifications**: Noticed gem integration
- **Deployment**: Kamal, Docker

### Key Architectural Patterns
- **MVC with Service Objects**: Clean separation of concerns
- **Policy-Based Authorization**: Fine-grained access control
- **Multi-Tenant Design**: Logical separation by teams and enterprise groups
- **Event-Driven Processing**: Background job architecture
- **RESTful Resources**: Consistent API design
- **Polymorphic Associations**: Flexible invitation system
- **Query Objects**: Complex database query optimization
- **ViewComponents**: Reusable UI components

### Triple-Track User System
```
1. Direct Users → Personal billing, can create teams
2. Invited Users → Team members only, shared billing
3. Enterprise Users → Organization-wide access, custom plans
```

### Current Application State (January 2025)
- **Test Coverage**: 1.33% line coverage (Critical - needs immediate attention)
- **Code Quality**: 253 RuboCop offenses
- **Security**: 1 minor Brakeman warning
- **Performance**: Excellent (<100ms response times, 0 N+1 queries)
- **Documentation**: Fully updated and consolidated

## 🔗 Architecture-Specific Resources

### Related Architecture Docs
- **[Business Logic](../guides/business-logic.md)** - Critical business rules and constraints
- **[Performance Guide](../guides/performance-guide.md)** - Optimization strategies  
- **[Common Pitfalls](../guides/common-pitfalls.md)** - Anti-patterns to avoid

### Key References
- **[Recent Updates](../RECENT_UPDATES.md)** - Architectural changes changelog
- **[Main Documentation Hub](../README.md)** - Complete documentation index

## 🚀 Quick Start for Developers

### Understanding the Codebase
1. Start with the [System Overview](01-system-overview.md) to understand the big picture
2. Review the [User Architecture](02-user-architecture.md) to understand the user model
3. Study the [Database Design](03-database-design.md) for data relationships
4. Check [Authentication](04-authentication.md) for security implementation

### Making Changes
1. Always consider the triple-track user system implications
2. Follow established patterns for controllers and services
3. Update tests and documentation with changes
4. Review security implications in the [Security Guide](../security/)

## 📊 Architecture Principles

### 1. Separation of Concerns
- Clear boundaries between user types
- Service objects for complex business logic
- Policies for authorization rules

### 2. Security First
- Multiple authentication layers
- Role-based access control
- Audit logging for critical actions

### 3. Scalability
- Stateless application design
- Database query optimization
- Caching strategies

### 4. Maintainability
- Consistent coding patterns
- Comprehensive documentation
- Test coverage target: 90% (currently at 1.33%)

## 🔄 Recent Updates

### January 2025
- **Documentation Consolidation**: Updated all docs, fixed metrics, removed duplicates
- **UI/UX Improvements**: Tailwind UI sidebar, navigation simplification, admin privileges
- **Enterprise Implementation**: Fixed circular dependencies, polymorphic invitations
- **Current State**: 1.33% test coverage, 253 RuboCop offenses, 1 Brakeman warning

### December 2024
- **Performance Optimizations**: Background job processing, caching strategy, database indexes
- **N+1 Query Elimination**: Query objects, eager loading, pre-calculated statistics

### Earlier 2024
- **Enterprise Features**: Complete enterprise organization management
- **Polymorphic Invitations**: Support for teams and enterprise groups
- **Security Enhancements**: Rack::Attack configuration, enterprise-specific policies
- **Tab Navigation**: Reusable ViewComponent for consistent interfaces

## 🎨 UI/UX Architecture

### Tailwind UI Integration
- **Light Theme Sidebar**: Modern, consistent navigation across all user types
- **Simplified Navigation**: User-specific items in avatar dropdown
- **Focus Management**: Keyboard-only focus indicators with `focus-visible`
- **Tab Components**: Reusable ViewComponent for complex interfaces

### Admin Enhancements
- **Subscription Bypass**: Super/site admins don't need paid subscriptions
- **Direct Email Changes**: Super admins can update email without confirmation
- **Enhanced Settings**: Comprehensive notification preferences with frequency options

## 🔧 Key Implementation Details

### Fixed Issues
- **Site Admin Navigation**: Corrected routes to prevent unauthorized team creation
- **Enterprise Creation**: Resolved circular dependency with invitation-based admin assignment
- **Icon System**: Standardized on `icon` helper (not `rails_icon`)
- **Pagination**: Updated to use `pagy_tailwind_nav` for Tailwind compatibility
- **JavaScript Modules**: Fixed importmap compatibility issues

### Best Practices Implemented
- **Separation of Concerns**: Enterprise controllers in dedicated namespace
- **Reusable Components**: ViewComponents for UI consistency
- **Polymorphic Patterns**: Flexible invitation system design
- **Audit Logging**: Comprehensive tracking of admin actions
- **Rate Limiting**: Separate limits for different user actions

## 📝 Contributing to Documentation

When updating architecture documentation:
1. Keep diagrams in sync with code changes
2. Update the "Last Updated" dates
3. Cross-reference related documents
4. Include code examples where helpful
5. Review for accuracy and completeness

### Priority Areas for Improvement
1. **Test Coverage**: Critical need to increase from 1.33% to 90%
2. **Code Quality**: Address 253 RuboCop offenses
3. **Security**: Resolve remaining Brakeman warning
4. **Documentation**: Continue expanding architecture guides

---

**Last Updated**: January 2025
**Maintained By**: Development Team
**Questions?**: See [CLAUDE.md](../../CLAUDE.md) for project specifications
**Navigation**: Return to [Main Documentation](../README.md)