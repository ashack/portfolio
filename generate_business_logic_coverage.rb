#!/usr/bin/env ruby

require 'csv'

# Business rules from business_logic.md with weights
BUSINESS_RULES = {
  # User Type System - Critical Rules (Weight 9-10)
  "CR-U1" => {
    code: "CR-U1",
    description: "User type immutability - cannot be changed after creation",
    category: "User Type System",
    weight: 10,
    risk: "HIGH",
    test_patterns: ["user type cannot be changed", "user_type immutability", "type immutable"]
  },
  "CR-U2" => {
    code: "CR-U2",
    description: "User type isolation - exclusive associations per type",
    category: "User Type System",
    weight: 10,
    risk: "HIGH",
    test_patterns: ["user type associations", "user type isolation", "direct users cannot have team", "invited users must have team", "enterprise users"]
  },
  "CR-U3" => {
    code: "CR-U3",
    description: "Direct user team ownership - only associated with owned teams",
    category: "User Type System",
    weight: 10,
    risk: "HIGH",
    test_patterns: ["direct users can own teams", "owns_team", "team ownership"]
  },
  
  # User Type System - Important Rules (Weight 6-8)
  "IR-U1" => {
    code: "IR-U1",
    description: "Email uniqueness across system",
    category: "User Type System",
    weight: 8,
    risk: "MEDIUM",
    test_patterns: ["email uniqueness", "unique email", "duplicate email"]
  },
  "IR-U2" => {
    code: "IR-U2",
    description: "Status management - only active users can sign in",
    category: "User Type System",
    weight: 7,
    risk: "MEDIUM",
    test_patterns: ["status management", "active users", "can_sign_in", "authentication status"]
  },
  "IR-U3" => {
    code: "IR-U3",
    description: "Email normalization - lowercase and trimmed",
    category: "User Type System",
    weight: 6,
    risk: "MEDIUM",
    test_patterns: ["email normalization", "normalize email", "lowercase email"]
  },
  
  # Authentication & Authorization - Critical Rules
  "CR-A1" => {
    code: "CR-A1",
    description: "Password complexity requirements",
    category: "Authentication & Authorization",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["password complexity", "password requirements", "password validation"]
  },
  "CR-A2" => {
    code: "CR-A2",
    description: "System role hierarchy and permissions",
    category: "Authentication & Authorization",
    weight: 10,
    risk: "HIGH",
    test_patterns: ["system role", "super admin", "site admin", "role hierarchy", "denies access to non-super-admins", "requires authentication", "should not get index as regular user"]
  },
  "CR-A3" => {
    code: "CR-A3",
    description: "Self-role change prevention",
    category: "Authentication & Authorization",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["self role change", "own role", "system_role_change_allowed"]
  },
  
  # Team Management - Critical Rules
  "CR-T1" => {
    code: "CR-T1",
    description: "Team creation authority - only Super Admins",
    category: "Team Management",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["team creation", "create team", "super admin"]
  },
  "CR-T2" => {
    code: "CR-T2",
    description: "Member limit enforcement per plan",
    category: "Team Management",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["member limit", "plan limit", "can_add_members", "max_members"]
  },
  "CR-T3" => {
    code: "CR-T3",
    description: "Admin requirement - team must have admin",
    category: "Team Management",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["admin requirement", "last admin", "admin presence", "delete last admin"]
  },
  "CR-T4" => {
    code: "CR-T4",
    description: "Team billing independence",
    category: "Team Management",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["team billing", "stripe subscription", "pay_customer"]
  },
  
  # Team Management - Important Rules
  "IR-T1" => {
    code: "IR-T1",
    description: "Slug uniqueness and URL safety",
    category: "Team Management",
    weight: 7,
    risk: "MEDIUM",
    test_patterns: ["slug unique", "slug generation", "url safe"]
  },
  "IR-T2" => {
    code: "IR-T2",
    description: "User deletion prevention with members",
    category: "Team Management",
    weight: 8,
    risk: "MEDIUM",
    test_patterns: ["deletion prevention", "restrict_with_error", "team with users"]
  },
  
  # Enterprise Groups
  "CR-E1" => {
    code: "CR-E1",
    description: "Admin assignment via invitation",
    category: "Enterprise Groups",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["enterprise admin", "admin assignment", "invitation acceptance"]
  },
  "CR-E2" => {
    code: "CR-E2",
    description: "Enterprise user isolation",
    category: "Enterprise Groups",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["enterprise isolation", "enterprise users cannot", "enterprise associations"]
  },
  
  # Invitation System - Critical Rules
  "CR-I1" => {
    code: "CR-I1",
    description: "New email only - not in users table",
    category: "Invitation System",
    weight: 10,
    risk: "HIGH",
    test_patterns: ["email not in users", "new email only", "existing user", "email must not exist", "email cannot exist in users table", "invitation email cannot exist in users table"]
  },
  "CR-I2" => {
    code: "CR-I2",
    description: "Invitation expiration after 7 days",
    category: "Invitation System",
    weight: 8,
    risk: "MEDIUM",
    test_patterns: ["invitation expir", "expires_at", "7 days"]
  },
  "CR-I3" => {
    code: "CR-I3",
    description: "Polymorphic type safety",
    category: "Invitation System",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["polymorphic", "invitable", "invitation type"]
  },
  "CR-I4" => {
    code: "CR-I4",
    description: "Invitation acceptance creates correct user type",
    category: "Invitation System",
    weight: 10,
    risk: "HIGH",
    test_patterns: ["accept creates", "user type on accept", "invitation acceptance", "accept! creates correct user type with proper associations"]
  },
  
  # Invitation System - Important Rules
  "IR-I1" => {
    code: "IR-I1",
    description: "Token uniqueness",
    category: "Invitation System",
    weight: 8,
    risk: "MEDIUM",
    test_patterns: ["token unique", "secure token", "invitation token"]
  },
  
  # Billing & Subscriptions
  "CR-B1" => {
    code: "CR-B1",
    description: "Billing separation - team vs individual",
    category: "Billing & Subscriptions",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["billing separation", "separate billing", "team billing", "individual billing"]
  },
  "CR-B2" => {
    code: "CR-B2",
    description: "Plan enforcement - features and limits",
    category: "Billing & Subscriptions",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["plan enforcement", "plan features", "plan limits"]
  },
  "CR-B3" => {
    code: "CR-B3",
    description: "Plan segmentation by user type",
    category: "Billing & Subscriptions",
    weight: 8,
    risk: "HIGH",
    test_patterns: ["plan segment", "individual team enterprise", "plan_segment"]
  },
  
  # Security Constraints
  "CR-S1" => {
    code: "CR-S1",
    description: "CSRF protection",
    category: "Security Constraints",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["csrf", "forgery protection"]
  },
  "CR-S2" => {
    code: "CR-S2",
    description: "Mass assignment protection",
    category: "Security Constraints",
    weight: 9,
    risk: "HIGH",
    test_patterns: ["strong parameters", "mass assignment", "permit"]
  },
  
  # Data Integrity
  "CR-D1" => {
    code: "CR-D1",
    description: "Foreign key integrity",
    category: "Data Integrity",
    weight: 8,
    risk: "HIGH",
    test_patterns: ["foreign key", "referential integrity", "belongs_to"]
  },
  "CR-D2" => {
    code: "CR-D2",
    description: "Email normalization in all models",
    category: "Data Integrity",
    weight: 7,
    risk: "MEDIUM",
    test_patterns: ["email normal", "lowercase email", "strip email"]
  }
}

# Extract all tests from test files
def extract_tests_from_files
  tests = []
  
  Dir.glob('test/**/*_test.rb').each do |file_path|
    next if file_path.include?('test_helper')
    
    File.readlines(file_path).each_with_index do |line, index|
      if match = line.match(/^\s*test\s+["'](.+?)["']\s+do/)
        test_name = match[1]
        tests << {
          test_name: test_name,
          file_path: file_path,
          line_number: index + 1,
          normalized_name: test_name.downcase
        }
      end
    end
  end
  
  tests
end

# Match tests to business rules
def match_test_to_rules(test)
  matched_rules = []
  
  BUSINESS_RULES.each do |code, rule|
    rule[:test_patterns].each do |pattern|
      if test[:normalized_name].include?(pattern.downcase)
        matched_rules << rule
        break
      end
    end
  end
  
  matched_rules
end

# Generate coverage report
puts "Extracting tests from files..."
all_tests = extract_tests_from_files
puts "Found #{all_tests.length} tests"

# Map tests to business rules
test_mappings = []
unmatched_tests = []

all_tests.each do |test|
  matched_rules = match_test_to_rules(test)
  
  if matched_rules.empty?
    unmatched_tests << test
  else
    matched_rules.each do |rule|
      test_mappings << {
        test_name: test[:test_name],
        file_path: test[:file_path],
        line_number: test[:line_number],
        business_rule_code: rule[:code],
        business_rule: rule[:description],
        category: rule[:category],
        weight: rule[:weight],
        risk_level: rule[:risk],
        coverage_status: "covered"
      }
    end
  end
end

# Find uncovered rules
covered_rule_codes = test_mappings.map { |m| m[:business_rule_code] }.uniq
uncovered_rules = BUSINESS_RULES.reject { |code, _| covered_rule_codes.include?(code) }

# Add uncovered rules to the report
uncovered_rules.each do |code, rule|
  test_mappings << {
    test_name: "NO TEST COVERAGE",
    file_path: "N/A",
    line_number: "N/A",
    business_rule_code: rule[:code],
    business_rule: rule[:description],
    category: rule[:category],
    weight: rule[:weight],
    risk_level: rule[:risk],
    coverage_status: "NOT COVERED"
  }
end

# Sort by weight (descending) and then by category
test_mappings.sort_by! { |m| [-m[:weight], m[:category], m[:business_rule_code]] }

# Write CSV
CSV.open('docs/business_logic_test_coverage.csv', 'w') do |csv|
  csv << ['test_name', 'file_path', 'line_number', 'business_rule_code', 'business_rule', 'category', 'weight', 'risk_level', 'coverage_status']
  
  test_mappings.each do |mapping|
    csv << [
      mapping[:test_name],
      mapping[:file_path],
      mapping[:line_number],
      mapping[:business_rule_code],
      mapping[:business_rule],
      mapping[:category],
      mapping[:weight],
      mapping[:risk_level],
      mapping[:coverage_status]
    ]
  end
end

# Generate summary report
puts "\n=== Business Logic Test Coverage Report ==="
puts "\nTotal business rules: #{BUSINESS_RULES.length}"
puts "Covered rules: #{covered_rule_codes.length}"
puts "Uncovered rules: #{uncovered_rules.length}"
puts "Coverage: #{(covered_rule_codes.length.to_f / BUSINESS_RULES.length * 100).round(1)}%"

# Coverage by weight
weight_groups = test_mappings.group_by { |m| 
  case m[:weight]
  when 9..10 then "Critical (9-10)"
  when 6..8 then "Important (6-8)"
  when 3..5 then "Standard (3-5)"
  else "Low (1-2)"
  end
}

puts "\nCoverage by Priority:"
weight_groups.each do |priority, mappings|
  covered = mappings.count { |m| m[:coverage_status] == "covered" }
  total = mappings.map { |m| m[:business_rule_code] }.uniq.length
  puts "  #{priority}: #{covered}/#{total} rules covered"
end

# High risk uncovered rules
high_risk_uncovered = uncovered_rules.select { |_, rule| rule[:risk] == "HIGH" }
if high_risk_uncovered.any?
  puts "\n⚠️  HIGH RISK RULES WITHOUT COVERAGE:"
  high_risk_uncovered.each do |code, rule|
    puts "  - #{code}: #{rule[:description]} (Weight: #{rule[:weight]})"
  end
end

puts "\nDetailed coverage saved to: docs/business_logic_test_coverage.csv"
puts "Unmatched tests: #{unmatched_tests.length}"

# Save unmatched tests for review
if unmatched_tests.any?
  CSV.open('docs/unmatched_tests.csv', 'w') do |csv|
    csv << ['test_name', 'file_path', 'line_number']
    unmatched_tests.each do |test|
      csv << [test[:test_name], test[:file_path], test[:line_number]]
    end
  end
  puts "Unmatched tests saved to: docs/unmatched_tests.csv"
end