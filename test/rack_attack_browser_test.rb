#!/usr/bin/env ruby
# Test Rack::Attack with proper session handling

require "net/http"
require "uri"
require "json"

base_url = "http://localhost:3000"

puts "Testing Rack::Attack rate limiting with proper session handling..."
puts "-" * 50

# Test bypassing CSRF for testing purposes
puts "\n1. Testing general request throttling (60 requests per minute)..."
root_url = URI("#{base_url}/")

puts "Making rapid GET requests (these don't need CSRF tokens)..."
responses = []
65.times do |i|
  begin
    response = Net::HTTP.get_response(root_url)
    responses << response.code

    if response.code == "429"
      puts "\n✓ Rate limiting triggered after #{i + 1} requests!"
      body = JSON.parse(response.body) rescue response.body
      puts "Response: #{body}"
      break
    end

    print "." if i % 10 == 0
  rescue => e
    puts "\nError: #{e.message}"
  end
end

puts "\n\nResponses summary:"
puts "- 200 OK: #{responses.count('200')}"
puts "- 429 Too Many Requests: #{responses.count('429')}"
puts "- Other: #{responses.count { |code| code != '200' && code != '429' }}"

# Test suspicious paths
puts "\n2. Testing suspicious path blocking..."
suspicious_paths = [
  "/wp-admin",
  "/config.php",
  "/.env",
  "/.git/config",
  "/phpmyadmin"
]

suspicious_paths.each do |path|
  url = URI("#{base_url}#{path}")
  response = Net::HTTP.get_response(url)
  puts "#{path}: #{response.code} - #{response.message}"
  if response.code == "403"
    puts "  ✓ Blocked as expected"
  end
end

# Test with suspicious user agent
puts "\n3. Testing suspicious user agent blocking..."
uri = URI("#{base_url}/")
req = Net::HTTP::Get.new(uri)
req["User-Agent"] = "sqlmap/1.0"

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(req)
end

puts "Request with sqlmap user agent: #{response.code} - #{response.message}"
if response.code == "403"
  puts "✓ Blocked as expected"
end

puts "\n✓ Rack::Attack security tests completed!"
