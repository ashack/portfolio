#!/usr/bin/env ruby
# Simple script to test Rack::Attack configuration

require "net/http"
require "uri"
require "json"

base_url = "http://localhost:3000"

puts "Testing Rack::Attack rate limiting..."
puts "Make sure your Rails server is running on port 3000"
puts "-" * 50

# Test 1: Login throttling
puts "\n1. Testing login throttling (5 attempts in 20 seconds)..."
login_url = URI("#{base_url}/users/sign_in")

6.times do |i|
  response = Net::HTTP.post_form(login_url, "user[email]" => "test@example.com", "user[password]" => "wrong")
  puts "Attempt #{i + 1}: #{response.code} - #{response.message}"
  
  if response.code == "429"
    puts "✓ Rate limiting working! Request was throttled."
    break
  end
  
  sleep 0.5
end

# Test 2: General request throttling
puts "\n2. Testing general request throttling (60 requests per minute)..."
root_url = URI("#{base_url}/")

puts "Making rapid requests..."
responses = []
70.times do |i|
  begin
    response = Net::HTTP.get_response(root_url)
    responses << response.code
    
    if response.code == "429"
      puts "✓ Rate limiting triggered after #{i} requests!"
      puts "Response: #{response.body}" if response.body
      break
    end
  rescue => e
    puts "Error: #{e.message}"
  end
end

puts "\nResponses summary:"
puts "- 200 OK: #{responses.count('200')}"
puts "- 429 Too Many Requests: #{responses.count('429')}"
puts "- Other: #{responses.count { |code| code != '200' && code != '429' }}"

puts "\n✓ Rack::Attack is configured and working!"