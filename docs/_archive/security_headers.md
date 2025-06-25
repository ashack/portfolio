# Security Headers Configuration

## Overview

This application implements comprehensive security headers to protect against common web vulnerabilities including XSS, clickjacking, and content injection attacks.

## Implemented Security Headers

### 1. Content Security Policy (CSP)

**Configuration**: `config/initializers/content_security_policy.rb`

The CSP is configured with the following directives:

- **default-src**: `'self' https:` - Default to HTTPS sources
- **script-src**: `'self' https: 'unsafe-inline'` + CDNs - Allows Rails UJS and Turbo
- **style-src**: `'self' https: 'unsafe-inline'` - Required for Tailwind CSS
- **img-src**: `'self' https: data:` - Allows images from HTTPS and data URIs
- **connect-src**: `'self' https:` + Stripe APIs - For AJAX and WebSocket connections
- **frame-ancestors**: `'none'` - Prevents clickjacking
- **object-src**: `'none'` - Blocks plugins like Flash

**Environment Differences**:
- Development: Report-only mode (logs violations without blocking)
- Production: Enforcing mode with upgrade-insecure-requests

### 2. Security Headers Middleware

**Location**: `app/middleware/security_headers.rb`

Adds the following headers to all responses:

- **X-Frame-Options**: `DENY` - Prevents clickjacking
- **X-Content-Type-Options**: `nosniff` - Prevents MIME type sniffing
- **X-XSS-Protection**: `1; mode=block` - Legacy XSS protection
- **Referrer-Policy**: `strict-origin-when-cross-origin` - Controls referrer information
- **Permissions-Policy**: Disables unnecessary browser features
- **Strict-Transport-Security**: HSTS header (production only)

### 3. CSP Violation Reporting

**Endpoint**: `/csp_violation_reports`
**Controller**: `app/controllers/csp_reports_controller.rb`

- Receives CSP violation reports from browsers
- Logs violations for monitoring
- Can be integrated with error tracking services

## Testing Security Headers

### Manual Testing

Run the provided test script:
```bash
ruby test/security_headers_test.rb
```

### Using curl

Test individual headers:
```bash
# Check all headers
curl -I http://localhost:3000

# Check CSP header
curl -I http://localhost:3000 | grep -i content-security-policy

# Check security headers
curl -I http://localhost:3000 | grep -E "(X-Frame-Options|X-Content-Type|X-XSS-Protection|Referrer-Policy)"
```

### Browser Testing

1. Open Chrome DevTools → Network tab
2. Load any page
3. Click on the main document request
4. Check Response Headers section

## Production Configuration

### Environment Variables

Add to production environment:
```bash
# CSP violation reporting service (optional)
CSP_REPORT_URI=https://your-monitoring-service.com/csp-reports

# Force SSL/HSTS
RAILS_FORCE_SSL=true
```

### nginx Configuration

If using nginx, add complementary headers:
```nginx
# Additional security headers
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

## Customization

### Adjusting CSP for Specific Pages

For pages that need different CSP rules:

```ruby
# In a specific controller
content_security_policy do |policy|
  policy.script_src :self, :unsafe_inline, :unsafe_eval  # For admin analytics
end
```

### Adding External Resources

To allow specific external resources:

```ruby
# In content_security_policy.rb
policy.img_src :self, :https, :data, 'https://cdn.example.com'
policy.script_src :self, :https, 'https://trusted-cdn.com'
```

### Disabling Headers for Specific Routes

```ruby
# In a controller
skip_before_action :set_security_headers, only: [:api_endpoint]
```

## Monitoring & Compliance

### CSP Violations

Monitor CSP violations in logs:
```bash
# Development
tail -f log/development.log | grep "CSP Violation"

# Production
grep "CSP Violation" log/production.log
```

### Security Testing Tools

- [Security Headers](https://securityheaders.com/) - Online header scanner
- [Mozilla Observatory](https://observatory.mozilla.org/) - Comprehensive security scan
- [CSP Evaluator](https://csp-evaluator.withgoogle.com/) - Google's CSP validator

### Expected Scores

With this configuration, you should achieve:
- Security Headers: A+ rating
- Mozilla Observatory: A rating
- SSL Labs: A+ rating (with proper SSL configuration)

## Common Issues

### 1. Inline Scripts Blocked

**Problem**: Rails UJS or Turbo features not working

**Solution**: Already configured with `unsafe-inline` for scripts. For better security, consider using nonces:
```erb
<%= javascript_tag nonce: true do %>
  // Your inline script
<% end %>
```

### 2. External Resources Blocked

**Problem**: CDN resources or third-party services blocked

**Solution**: Add specific sources to CSP:
```ruby
policy.script_src :self, :https, 'https://specific-cdn.com'
```

### 3. Form Submissions Blocked

**Problem**: Forms submitting to external services fail

**Solution**: Update form-action directive:
```ruby
policy.form_action :self, 'https://external-form-handler.com'
```

## Security Best Practices

1. **Regular Reviews**: Review CSP violations monthly
2. **Gradual Tightening**: Start permissive, tighten over time
3. **Testing**: Test thoroughly after CSP changes
4. **Monitoring**: Set up alerts for unusual violation patterns
5. **Documentation**: Document all CSP exceptions and reasons

## Next Steps

1. **Deploy to Staging**: Test headers in production-like environment
2. **Monitor Violations**: Set up violation tracking
3. **Tighten Policy**: Remove `unsafe-inline` where possible
4. **Add Subresource Integrity**: For external scripts/styles
5. **Implement Feature Policy**: Further restrict browser features