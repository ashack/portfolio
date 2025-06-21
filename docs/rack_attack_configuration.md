# Rack::Attack Security Configuration

## Overview

Rack::Attack is configured to provide comprehensive rate limiting and security protection for the SaaS application. This document outlines the security measures implemented.

## Current Status

✅ **Fully Configured and Tested**
- Rate limiting rules are active
- Security blocklists are functioning
- Localhost is safelisted for development
- All security events are logged

## Rate Limiting Rules

### 1. General Request Throttling
- **Limit**: 60 requests per minute per IP (300 requests per 5 minutes in production)
- **Excludes**: Asset requests (/assets, /packs)
- **Purpose**: Prevent general abuse and DoS attempts

### 2. Authentication Throttling

#### Login Attempts
- **Limit**: 5 attempts per 20 seconds per IP
- **Path**: `/users/sign_in` (POST)
- **Purpose**: Prevent brute force attacks

#### Password Reset
- **Limit**: 5 attempts per hour per IP
- **Path**: `/users/password` (POST)
- **Purpose**: Prevent password reset spam

#### Sign Up
- **Limit**: 3 attempts per hour per IP
- **Path**: `/users` (POST)
- **Purpose**: Prevent spam account creation

### 3. Team-Specific Throttling

#### Team Invitations
- **Limit**: 20 invitations per day per authenticated user
- **Path**: `/teams/*/admin/invitations` (POST)
- **Purpose**: Prevent invitation spam

### 4. Enterprise-Specific Throttling

#### Enterprise Invitations
- **Limit**: 30 invitations per day per authenticated user
- **Path**: `/enterprise/*/members` (POST)
- **Purpose**: Prevent invitation spam in enterprise groups

#### Enterprise Admin Actions
- **Limit**: 100 administrative actions per hour per authenticated user
- **Paths**: 
  - `/admin/super/enterprise_groups/*` (POST, PATCH, DELETE)
  - `/enterprise/*/settings` (PATCH)
  - `/enterprise/*/members/*/revoke_invitation` (DELETE)
- **Purpose**: Prevent abuse of administrative functions

### 5. API Throttling (Future)
- **Limit**: 100 requests per minute per authenticated user
- **Path**: `/api/*`
- **Purpose**: Fair API usage

## Security Blocklists

### 1. Fail2Ban Protection
- Blocks IPs for 10 minutes after 3 failed login attempts within 10 minutes
- Monitors failed authentication attempts

### 2. Suspicious User Agents
Blocks requests from known vulnerability scanners and bots:
- masscan
- nikto
- sqlmap
- benchmark
- httpclient
- python-requests
- go-http-client
- java
- libwww-perl

### 3. Suspicious Paths
Blocks requests to common vulnerability paths:
- PHP files (*.php)
- ASP files (*.asp, *.aspx)
- Environment files (.env)
- Version control (.git, .svn)
- WordPress paths (/wp-admin, /wp-login)
- phpMyAdmin paths
- Common backdoor filenames
- Enterprise paths without proper authentication

## Safelists

### Always Allowed
- Localhost (127.0.0.1, ::1) - for development
- Office/VPN IPs can be added in configuration

## Response Handling

### Throttled Requests (429)
```json
{
  "error": "Too many requests. Please try again later."
}
```
- Includes `Retry-After` header

### Blocked Requests (403)
```json
{
  "error": "Forbidden. Your request has been blocked."
}
```

## Monitoring & Logging

### Logged Events
1. **Throttled Requests**: Logged as warnings with IP, path, and rule
2. **Blocked Requests**: Logged as errors with IP, path, user agent, and rule
3. **Tracked Requests**: Logged as info for monitoring patterns

### Special Tracking
- Admin access from non-localhost IPs
- High-frequency requesters (>30 requests/minute)

## Cache Configuration

### Default
- Uses Rails cache (MemoryStore in development)

### Production Recommendation
```ruby
# Use Redis for distributed caching
Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])
```

## Configuration File Location

The main configuration is in `config/initializers/rack_attack.rb`

## Testing Rate Limits

### Development Testing

**Note**: Localhost is safelisted in development, so rate limits won't apply to 127.0.0.1 or ::1.

Use the provided test scripts:
```bash
# Test blocklists and basic functionality
ruby test/rack_attack_browser_test.rb

# View verification results
cat test/rack_attack_verification.md
```

### Production Testing

To test in production (from a non-safelisted IP):
```bash
# Test login throttling
for i in {1..6}; do
  curl -X POST http://localhost:3000/users/sign_in \
    -d "user[email]=test@example.com&user[password]=wrong" \
    -w "\nStatus: %{http_code}\n"
done
```

## Customization

### Adding New Throttle Rules
```ruby
throttle('custom/rule', limit: 10, period: 1.hour) do |req|
  # Your logic here
  req.ip if req.path == '/custom/path' && req.post?
end
```

### Enterprise-Specific Rules
```ruby
# Throttle enterprise invitation sending
throttle('enterprise/invitations', limit: 30, period: 1.day) do |req|
  if req.path =~ %r{^/enterprise/.+/members$} && req.post?
    req.authenticated_user_id
  end
end

# Throttle enterprise admin actions
throttle('enterprise/admin_actions', limit: 100, period: 1.hour) do |req|
  if req.path =~ %r{^/(admin/super/enterprise_groups|enterprise/.+/(settings|members/.+/revoke_invitation))} && 
     %w[POST PATCH DELETE].include?(req.request_method)
    req.authenticated_user_id
  end
end
```

### Adding IP to Safelist
```ruby
safelist('allow-office') do |req|
  ['192.168.1.100', '10.0.0.50'].include?(req.ip)
end
```

## Troubleshooting

### Rate Limit Too Strict
- Check development vs production configuration
- Verify cache is working properly
- Review logs for patterns

### Legitimate Users Blocked
- Add IPs to safelist
- Adjust limits based on usage patterns
- Monitor tracked requests for insights

### Performance Impact
- Use Redis cache in production
- Monitor middleware timing
- Consider async logging for high traffic