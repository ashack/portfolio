# Architecture Documentation

Welcome to the comprehensive architecture documentation for the SaaS Rails Starter Kit. This guide provides detailed technical information about the system design, implementation patterns, and architectural decisions.

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
- **Deployment**: Kamal, Docker

### Key Architectural Patterns
- **MVC with Service Objects**: Clean separation of concerns
- **Policy-Based Authorization**: Fine-grained access control
- **Multi-Tenant Design**: Logical separation by teams
- **Event-Driven Processing**: Background job architecture
- **RESTful Resources**: Consistent API design

### Triple-Track User System
```
1. Direct Users → Personal billing, can create teams
2. Invited Users → Team members only, shared billing
3. Enterprise Users → Organization-wide access, custom plans
```

## 🔗 Related Documentation

### Security & Compliance
- **[Security Guide](../security/)** - Authentication, authorization, and security best practices
- **[Business Logic](../guides/business-logic.md)** - Critical business rules and constraints

### Development Guides
- **[Testing Architecture](../guides/testing-guide.md)** - Test strategy and implementation
- **[Performance Guide](../guides/performance-guide.md)** - Optimization strategies
- **[Deployment Guide](../guides/deployment-guide.md)** - Production deployment
- **[Common Pitfalls](../guides/common-pitfalls.md)** - Anti-patterns to avoid

### Reference Documentation
- **[UI Components](../reference/ui-components.md)** - Component library reference
- **[Database Reference](../reference/database-reference.md)** - Schema details
- **[Configuration](../reference/configuration.md)** - Environment setup

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
- Extensive test coverage

## 🔄 Recent Updates

- **June 2025**: Enterprise features implementation
- **June 2025**: Polymorphic invitation system
- **June 2025**: Enhanced security with Rack::Attack
- **June 2025**: Rails 8.0.2 compatibility updates

## 📝 Contributing to Documentation

When updating architecture documentation:
1. Keep diagrams in sync with code changes
2. Update the "Last Updated" dates
3. Cross-reference related documents
4. Include code examples where helpful
5. Review for accuracy and completeness

---

**Last Updated**: June 2025
**Maintained By**: Development Team
**Questions?**: See [CLAUDE.md](../../CLAUDE.md) for project specifications