#!/usr/bin/env ruby
# Test script to verify security headers implementation

require 'net/http'
require 'uri'
require 'json'

base_url = 'http://localhost:3000'

puts "Testing Security Headers Implementation..."
puts "=" * 50
puts "Make sure your Rails server is running on port 3000"
puts "=" * 50

# Function to display header info
def display_header(name, value, expected)
  status = value&.include?(expected) ? "✅" : "❌"
  puts "#{status} #{name}: #{value || 'NOT SET'}"
  puts "   Expected: #{expected}" unless value&.include?(expected)
end

# Test 1: Check security headers on main page
puts "\n1. Testing Security Headers on Home Page..."
uri = URI("#{base_url}/")
response = Net::HTTP.get_response(uri)

puts "\nSecurity Headers:"
puts "-" * 30

# Check CSP header
csp = response['Content-Security-Policy']
csp_report_only = response['Content-Security-Policy-Report-Only']
if csp || csp_report_only
  puts "✅ Content-Security-Policy: #{csp_report_only ? 'Report-Only Mode' : 'Enforcing Mode'}"
  puts "   Policy: #{(csp || csp_report_only)[0..100]}..." if csp || csp_report_only
else
  puts "❌ Content-Security-Policy: NOT SET"
end

# Check other security headers
display_header("X-Frame-Options", response['X-Frame-Options'], "DENY")
display_header("X-Content-Type-Options", response['X-Content-Type-Options'], "nosniff")
display_header("X-XSS-Protection", response['X-XSS-Protection'], "1; mode=block")
display_header("Referrer-Policy", response['Referrer-Policy'], "strict-origin-when-cross-origin")
display_header("Permissions-Policy", response['Permissions-Policy'], "accelerometer=(), camera=()")

# Check for HSTS in production
if response['Strict-Transport-Security']
  puts "✅ Strict-Transport-Security: #{response['Strict-Transport-Security']}"
else
  puts "ℹ️  Strict-Transport-Security: Not set (normal in development)"
end

# Check for headers that should be removed
puts "\nHeaders that should be removed:"
puts "-" * 30
removed_headers = ['X-Powered-By', 'Server']
removed_headers.each do |header|
  if response[header]
    puts "❌ #{header}: Still present (#{response[header]})"
  else
    puts "✅ #{header}: Properly removed"
  end
end

# Test 2: Test CSP violation reporting
puts "\n\n2. Testing CSP Violation Reporting..."
puts "-" * 30

violation_report = {
  "csp-report" => {
    "document-uri" => "http://localhost:3000/test",
    "violated-directive" => "script-src",
    "blocked-uri" => "http://evil.com/bad.js",
    "line-number" => 10,
    "source-file" => "http://localhost:3000/test.js",
    "original-policy" => "script-src 'self'"
  }
}

uri = URI("#{base_url}/csp_violation_reports")
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri)
request['Content-Type'] = 'application/csp-report'
request.body = violation_report.to_json

begin
  response = http.request(request)
  if response.code == "204"
    puts "✅ CSP violation reporting endpoint working (204 No Content)"
  else
    puts "❌ CSP violation reporting returned: #{response.code} #{response.message}"
  end
rescue => e
  puts "❌ Error testing CSP reporting: #{e.message}"
end

# Test 3: Check login page for form action
puts "\n\n3. Testing Form Security on Login Page..."
puts "-" * 30

uri = URI("#{base_url}/users/sign_in")
response = Net::HTTP.get_response(uri)

if response.code == "200"
  body = response.body
  
  # Check for CSRF token
  if body.include?('csrf-token')
    puts "✅ CSRF token meta tag present"
  else
    puts "❌ CSRF token meta tag missing"
  end
  
  # Check for form authenticity token
  if body.include?('authenticity_token')
    puts "✅ Form authenticity token present"
  else
    puts "❌ Form authenticity token missing"
  end
else
  puts "⚠️  Could not access login page: #{response.code}"
end

# Summary
puts "\n" + "=" * 50
puts "Security Headers Test Complete!"
puts "=" * 50
puts "\nRecommendations:"
puts "- In production, ensure HSTS is enabled"
puts "- Monitor CSP violations in production logs"
puts "- Regularly review and update CSP policy"
puts "- Consider adding report-uri for production CSP monitoring"