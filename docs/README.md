# Rails SaaS Starter - Documentation

*Last Updated: January 2025*

Welcome to the Rails SaaS Starter documentation. This guide helps you navigate all available documentation for this production-ready triple-track SaaS application.

## 🚀 Quick Start

### New Developers
1. [Architecture Overview](architecture/README.md) - Understand the system design
2. [Development Guide](development_guide.md) - Set up your environment
3. [Recent Updates](recent_updates.md) - See what's new

### Common Tasks
- **Fixing Bugs**: [Bug Fixes & Troubleshooting](bug_fixes.md)
- **Adding Features**: [Development Guide](development_guide.md) + [Project Status](project_status.md)
- **Code Review**: [Improvements Guide](improvements.md)
- **Security Audit**: [Security Guide](security/README.md)

## 📚 Core Documentation

### [Bug Fixes & Troubleshooting](bug_fixes.md)
Solutions for Rails 8.0.2 compatibility issues, authentication problems, and common errors.

### [Improvements Guide](improvements.md)
Comprehensive recommendations for code quality, performance, and maintainability.

### [Recent Updates](recent_updates.md)
Changelog documenting the evolution to triple-track system with enterprise support.

### [Development Guide](development_guide.md)
Development workflow, guidelines, code review process, and deployment procedures.

### [Project Status](project_status.md)
Current metrics, feature completion status, pending tasks, and roadmap.

**Current Health**: 🔴 Test Coverage: 1.33% | 🟡 Code Quality: 253 RuboCop offenses | ✅ Performance: <100ms response times

## 📖 Specialized Guides

### System Design
- [Architecture Overview](architecture/README.md) - System architecture and technical decisions
- [Database Design](architecture/03-database-design.md) - Schema and relationships
- [User Architecture](architecture/02-user-architecture.md) - Triple-track user system

### Security
- [Security Overview](security/README.md) - Security implementation guide
- [Authentication](security/authentication.md) - Devise configuration
- [Authorization](security/authorization.md) - Pundit policies
- [Rate Limiting](security/rack-attack.md) - Rack::Attack configuration

### Testing
- [Testing Overview](testing/README.md) - Testing strategy and setup
- [Test Coverage](testing/02-test-coverage.md) - Coverage reports and metrics
- [Business Logic Coverage](business_logic_coverage_summary.md) - Business rule test analysis

### Features & Guides
- [Enterprise Features](guides/enterprise-features.md) - Enterprise organization management
- [Common Pitfalls](guides/common-pitfalls.md) - Anti-patterns and best practices
- [Performance Guide](guides/performance-guide.md) - Optimization strategies
- [Business Logic](guides/business-logic.md) - Core business rules

### Reference
- [UI Components](reference/ui-components.md) - Component library and patterns
- [UI/UX Improvements](ui_ux_improvements.md) - Modern UI implementation guide
- [Tab Navigation](tab_navigation.md) - Tab component documentation
- [Consolidation Summary](CONSOLIDATION_SUMMARY.md) - Documentation reorganization notes

## 📂 Directory Structure

```
docs/
├── Core Documentation
│   ├── bug_fixes.md
│   ├── improvements.md
│   ├── recent_updates.md
│   ├── development_guide.md
│   ├── project_status.md
│   └── ui_ux_improvements.md
│
├── architecture/          # System design docs
├── security/             # Security guides
├── testing/              # Testing documentation
├── guides/               # How-to guides
├── reference/            # Reference materials
└── _archive/             # Historical docs
```

## 📝 Documentation Standards

- **Naming**: lowercase_with_underscores.md
- **Dating**: Include "Last Updated" at the top
- **Linking**: Cross-reference related documents
- **Focus**: One topic per document
- **Examples**: Include practical code samples

## 🎯 Priority Areas for Improvement

1. **Test Coverage**: Critical need to increase from 1.33% to 90%
2. **Code Quality**: Address 253 RuboCop offenses
3. **Security**: Resolve remaining Brakeman warning
4. **Documentation**: Continue expanding architecture guides

See [Architecture Priority Areas](architecture/README.md#priority-areas-for-improvement) for details.

## 🔍 Need Help?

- **Bug?** → [Bug Fixes](bug_fixes.md)
- **Feature?** → [Development Guide](development_guide.md)
- **Security?** → [Security Guide](security/README.md)
- **Performance?** → [Improvements Guide](improvements.md#performance-optimizations)
- **Testing?** → [Testing Guide](testing/README.md)

---

For archived documentation, see the `_archive/` directory.