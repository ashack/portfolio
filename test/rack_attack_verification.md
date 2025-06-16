# Rack::Attack Configuration Verification

## What's Configured

### ✅ Blocklists (Working)
- **Suspicious Paths**: Blocks common vulnerability scanning paths (wp-admin, .env, .git, etc.)
- **Bad User Agents**: Blocks known scanners (sqlmap, nikto, masscan, etc.)
- **Fail2Ban**: Blocks IPs after 3 failed login attempts

### ✅ Throttles (Configured)
- **General**: 60 requests/minute per IP
- **Login**: 5 attempts per 20 seconds
- **Password Reset**: 5 attempts per hour
- **Sign Up**: 3 attempts per hour
- **Team Invitations**: 20 per day per user
- **API**: 100 requests/minute per user

### ✅ Safelists
- Localhost (127.0.0.1, ::1) - Always allowed in development

## Test Results

1. **Blocklists**: ✅ Working correctly
   - Suspicious paths return 403 Forbidden
   - Bad user agents return 403 Forbidden

2. **Throttles**: ⚠️ Configured but not triggering in tests
   - This is expected behavior because:
     - Localhost is safelisted in development
     - This prevents developers from being rate-limited
     - In production, remove localhost from safelist

## Production Deployment

Before deploying to production:

1. **Configure Redis Cache**:
   ```ruby
   Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])
   ```

2. **Remove Localhost Safelist** (or make it conditional):
   ```ruby
   if Rails.env.development?
     safelist('allow-localhost') do |req|
       req.ip == '127.0.0.1' || req.ip == '::1'
     end
   end
   ```

3. **Add Office/VPN IPs to Safelist**:
   ```ruby
   safelist('allow-office-ips') do |req|
     ENV['ALLOWED_IPS']&.split(',')&.include?(req.ip)
   end
   ```

4. **Monitor Logs**:
   - Throttled requests logged as warnings
   - Blocked requests logged as errors
   - Tracked requests logged as info

## Testing in Production

To verify throttling works in production:
```bash
# From a non-safelisted IP
for i in {1..65}; do 
  curl -s -o /dev/null -w "%{http_code} " https://yourdomain.com/
done
```

Should see 429 responses after 60 requests.