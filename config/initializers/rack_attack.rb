# Rack::Attack configuration for rate limiting and security
class Rack::Attack
  # Cache store configuration (uses Rails cache by default)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Configure Cache ###
  # If you're using Redis or another cache backend:
  # Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])

  ### Throttle Configurations ###

  # Throttle all requests by IP (60rpm)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  # Throttle POST requests to /login by IP
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle password reset requests
  throttle('password_resets/ip', limit: 5, period: 1.hour) do |req|
    if req.path == '/users/password' && req.post?
      req.ip
    end
  end

  # Throttle sign up attempts by IP
  throttle('signups/ip', limit: 3, period: 1.hour) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end

  # Throttle team invitations by authenticated user
  throttle('invitations/user', limit: 20, period: 1.day) do |req|
    if req.path.match?(%r{/teams/.+/admin/invitations}) && req.post?
      req.env['warden'].user&.id if req.env['warden'].user
    end
  end

  # Throttle API requests by authenticated user (if you have an API)
  throttle('api/user', limit: 100, period: 1.minute) do |req|
    if req.path.start_with?('/api/')
      req.env['warden'].user&.id if req.env['warden'].user
    end
  end

  ### Fail2Ban-Style Blocking ###

  # Block suspicious requests for 10 minutes after 3 failed login attempts
  Rack::Attack.blocklist('fail2ban/logins') do |req|
    # Using a different cache key to track failed attempts
    Rack::Attack::Fail2Ban.filter("fail2ban:login:#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 10.minutes) do
      # This block is called only on POST /users/sign_in requests
      # Return true for failed login attempts
      req.path == '/users/sign_in' && req.post? && 
        req.env['warden'] && !req.env['warden'].authenticated?
    end
  end

  ### Safelist Configuration ###

  # Always allow requests from localhost (development)
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end

  # Allow specific IPs (add your office/VPN IPs here)
  # safelist('allow-office-ips') do |req|
  #   ['192.168.1.100', '10.0.0.50'].include?(req.ip)
  # end

  ### Blocklist Configuration ###

  # Block suspicious user agents
  blocklist('bad-user-agents') do |req|
    # Block common bot/scanner user agents
    bad_agents = [
      /masscan/i,
      /nikto/i,
      /sqlmap/i,
      /benchmark/i,
      /httpclient/i,
      /python-requests/i,
      /go-http-client/i,
      /java/i,
      /libwww-perl/i
    ]
    
    bad_agents.any? { |agent| req.user_agent&.match?(agent) }
  end

  # Block requests with suspicious paths
  blocklist('suspicious-paths') do |req|
    # Block common vulnerability scanning paths
    suspicious_paths = [
      /\.php$/,
      /\.asp$/,
      /\.aspx$/,
      /\.env/,
      /\.git/,
      /\.svn/,
      /\.DS_Store/,
      /wp-admin/,
      /wp-login/,
      /wordpress/,
      /phpmyadmin/,
      /admin\.php/,
      /config\.php/,
      /install\.php/,
      /setup\.php/
    ]
    
    suspicious_paths.any? { |path| req.path.match?(path) }
  end

  ### Custom Response Messages ###

  # Customize response for throttled requests
  self.throttled_responder = lambda do |req|
    retry_after = (req.env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{ error: 'Too many requests. Please try again later.' }.to_json]
    ]
  end

  # Customize response for blocked requests
  self.blocklisted_responder = lambda do |_req|
    [
      403,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Forbidden. Your request has been blocked.' }.to_json]
    ]
  end

  ### Logging ###

  # Log throttled requests
  ActiveSupport::Notifications.subscribe('throttle.rack_attack') do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled: #{req.env['rack.attack.matched']} from IP: #{req.ip} path: #{req.path}"
  end

  # Log blocked requests
  ActiveSupport::Notifications.subscribe('blocklist.rack_attack') do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.error "[Rack::Attack] Blocked: #{req.env['rack.attack.matched']} from IP: #{req.ip} path: #{req.path} user_agent: #{req.user_agent}"
  end

  ### Track Configuration (for monitoring without blocking) ###

  # Track requests that might be suspicious but don't block yet
  track('special/admin-access') do |req|
    req.path.start_with?('/admin/super') && req.ip != '127.0.0.1'
  end

  # Track high-frequency requesters (for analysis)
  track('special/frequent-requests') do |req|
    req.ip if req.ip && Rack::Attack.cache.count("track:requests:#{req.ip}", 1.minute) > 30
  end

  # Log tracked requests for monitoring
  ActiveSupport::Notifications.subscribe('track.rack_attack') do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.info "[Rack::Attack] Tracked: #{req.env['rack.attack.matched']} from IP: #{req.ip} path: #{req.path}"
  end
end

# Environment-specific adjustments (without overriding existing throttles)
unless Rails.env.production?
  # Log that we're in development mode
  Rails.logger.info '[Rack::Attack] Running with development configuration'
  Rails.logger.info "[Rack::Attack] General throttle: 60 requests per minute"
end