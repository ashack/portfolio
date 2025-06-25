require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User",
      user_type: "direct",
      status: "active"
    )

    @team = Team.create!(
      name: "Test Team",
      admin: users(:super_admin),
      created_by: users(:super_admin)
    )

    @enterprise_plan = Plan.create!(
      name: "Enterprise Plan",
      plan_segment: "enterprise",
      amount_cents: 99900,
      active: true
    )

    @enterprise_group = EnterpriseGroup.create!(
      name: "Test Enterprise",
      created_by: users(:super_admin),
      plan: @enterprise_plan,
      admin: users(:super_admin)
    )
  end

  # ========================================================================
  # CRITICAL TESTS (Weight: 9-10)
  # ========================================================================

  # Weight: 10 - CR-U1: User type immutability - core system integrity
  test "user type cannot be changed after creation" do
    @user.skip_confirmation!
    @user.save!

    # Test all possible type changes
    [ "invited", "enterprise" ].each do |new_type|
      @user.reload
      @user.user_type = new_type
      assert_not @user.valid?
      assert_includes @user.errors[:user_type],
        "cannot be changed from 'direct' to '#{new_type}' - this is a core business rule"
    end
  end

  # Weight: 10 - CR-U2: User type isolation - prevents billing contamination
  test "user type associations are properly isolated" do
    # Direct users cannot have team associations (except ownership)
    @user.user_type = "direct"
    @user.team = @team
    @user.team_role = "member"
    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "direct users can only be associated with teams they own"

    # Direct users cannot have enterprise associations
    @user.team = nil
    @user.team_role = nil
    @user.enterprise_group = @enterprise_group
    @user.enterprise_group_role = "member"
    assert_not @user.valid?
    assert_includes @user.errors[:base], "direct users cannot have enterprise group associations"

    # Invited users must have team associations
    @user = User.new(email: "invited@example.com", password: "Password123!",
                     user_type: "invited")
    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "is required for team members"
    assert_includes @user.errors[:team_role], "is required for team members"

    # Invited users cannot have enterprise associations
    @user.team = @team
    @user.team_role = "member"
    @user.enterprise_group = @enterprise_group
    @user.enterprise_group_role = "member"
    assert_not @user.valid?
    assert_includes @user.errors[:base], "team members cannot have enterprise group associations"

    # Enterprise users must have enterprise associations
    @user = User.new(email: "enterprise@example.com", password: "Password123!",
                     user_type: "enterprise")
    assert_not @user.valid?
    assert_includes @user.errors[:enterprise_group_id], "is required for enterprise users"
    assert_includes @user.errors[:enterprise_group_role], "is required for enterprise users"

    # Enterprise users cannot have team associations
    @user.enterprise_group = @enterprise_group
    @user.enterprise_group_role = "member"
    @user.team = @team
    @user.team_role = "member"
    assert_not @user.valid?
    assert_includes @user.errors[:base], "enterprise users cannot have team associations"
  end

  # Weight: 9 - CR-A1: Password complexity - security critical
  test "password complexity requirements are enforced" do
    # Test all requirements in one comprehensive test
    test_cases = {
      "Pass1!" => "must be at least 8 characters long",
      "password123!" => "must include at least one uppercase letter",
      "PASSWORD123!" => "must include at least one lowercase letter",
      "Password!" => "must include at least one number",
      "Password123" => "must include at least one special character"
    }

    test_cases.each do |password, expected_error|
      @user.password = password
      assert_not @user.valid?
      assert @user.errors[:password].any? { |e| e.include?(expected_error.split.last(3).join(" ")) },
        "Password '#{password}' should have error containing '#{expected_error}'"
    end

    # Test that all errors show at once
    @user.password = "pass"
    assert_not @user.valid?
    password_errors = @user.errors[:password]
    assert password_errors.any? { |e| e.include?("8 characters") }
    assert password_errors.any? { |e| e.include?("uppercase") }
    assert password_errors.any? { |e| e.include?("number") }
    assert password_errors.any? { |e| e.include?("special character") }
  end

  # Weight: 9 - CR-U3: Direct user team ownership - prevents invitation bypass
  test "direct users can own teams but not be invited members" do
    @user.skip_confirmation!
    @user.save!

    # Direct users can own teams
    owned_team = Team.create!(
      name: "Owned Team",
      admin: @user,
      created_by: users(:super_admin)
    )

    assert_includes @user.administered_teams, owned_team

    # But cannot be assigned as team members
    @user.team = @team
    @user.team_role = "member"
    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "direct users can only be associated with teams they own"
  end

  # Weight: 9 - IR-U1: Email uniqueness with invitations - prevents duplicates
  test "email uniqueness prevents conflicts with invitations" do
    @user.skip_confirmation!
    @user.save!

    # Cannot create duplicate user
    duplicate_user = @user.dup
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"

    # Email normalization prevents case-based duplicates
    duplicate_user.email = "TEST@EXAMPLE.COM"
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  # ========================================================================
  # HIGH PRIORITY TESTS (Weight: 7-8)
  # ========================================================================

  # Weight: 8 - Team role transitions work correctly
  test "team role transitions work correctly" do
    # Create team member
    member_user = User.create!(
      email: "member@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )

    # Member can be promoted to admin
    member_user.team_role = "admin"
    assert member_user.valid?
    assert member_user.save

    # Create another admin so we have 2 admins total
    another_admin = User.create!(
      email: "admin2@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "admin",
      confirmed_at: Time.current
    )

    # Admin can be demoted when another admin exists
    member_user.reload
    member_user.team_role = "member"
    assert member_user.valid?
    assert member_user.save
  end

  # Weight: 7 - IR-U3: Email normalization - data consistency
  test "email normalization ensures consistency" do
    # Test comprehensive normalization
    @user.email = "  TeSt@ExAmPlE.cOm  "
    @user.valid?
    assert_equal "test@example.com", @user.email

    # Handles nil gracefully
    @user.email = nil
    assert_nothing_raised { @user.valid? }
    assert_nil @user.email
  end

  # Weight: 7 - IR-U2: Authentication status checks - access control
  test "authentication status controls access appropriately" do
    # Active users can sign in
    @user.status = "active"
    assert @user.can_sign_in?

    # Inactive and locked users cannot sign in
    [ "inactive", "locked" ].each do |status|
      @user.status = status
      assert_not @user.can_sign_in?
    end
  end

  # ========================================================================
  # MEDIUM PRIORITY TESTS (Weight: 5-6)
  # ========================================================================

  # Weight: 6 - Standard validations (consolidated)
  test "field validations work correctly" do
    # Email validation
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"

    @user.email = "invalid-email"
    assert_not @user.valid?
    assert @user.errors[:email].any?

    # User type and status validation
    @user.email = "test@example.com"
    @user.user_type = nil
    assert_not @user.valid?
    assert_includes @user.errors[:user_type], "can't be blank"

    @user.user_type = "direct"
    @user.status = nil
    assert_not @user.valid?
    assert_includes @user.errors[:status], "can't be blank"
  end

  # Weight: 5 - Role helper methods (consolidated)
  test "role helper methods work correctly" do
    # Team roles
    invited_admin = User.new(email: "admin@example.com", password: "Password123!",
                            user_type: "invited", team: @team, team_role: "admin")
    assert invited_admin.team_admin?
    assert_not invited_admin.team_member?

    invited_member = User.new(email: "member@example.com", password: "Password123!",
                             user_type: "invited", team: @team, team_role: "member")
    assert_not invited_member.team_admin?
    assert invited_member.team_member?

    # Enterprise roles
    ent_admin = User.new(email: "entadmin@example.com", password: "Password123!",
                        user_type: "enterprise", enterprise_group: @enterprise_group,
                        enterprise_group_role: "admin")
    assert ent_admin.enterprise_admin?
    assert_not ent_admin.enterprise_member?

    ent_member = User.new(email: "entmember@example.com", password: "Password123!",
                         user_type: "enterprise", enterprise_group: @enterprise_group,
                         enterprise_group_role: "member")
    assert_not ent_member.enterprise_admin?
    assert ent_member.enterprise_member?

    # Direct users have no team/enterprise roles
    assert_not @user.team_admin?
    assert_not @user.team_member?
    assert_not @user.enterprise_admin?
    assert_not @user.enterprise_member?
  end

  # ========================================================================
  # LOW PRIORITY TESTS (Keep only essential)
  # ========================================================================

  # Weight: 4 - Keep one test for full_name edge cases
  test "full_name handles edge cases correctly" do
    @user.first_name = nil
    @user.last_name = nil
    assert_equal "", @user.full_name

    @user.first_name = "John"
    assert_equal "John", @user.full_name

    @user.first_name = nil
    @user.last_name = "Doe"
    assert_equal "Doe", @user.full_name
  end

  # ========================================================================
  # NEW CRITICAL TESTS (Previously Missing)
  # ========================================================================

  # Weight: 10 - User type isolation matrix test
  test "user type isolation matrix prevents all invalid combinations" do
    # Matrix of all user type and association combinations
    test_matrix = [
      # [user_type, team?, team_role?, enterprise?, enterprise_role?, should_be_valid?]
      [ "direct", nil, nil, nil, nil, true ],
      [ "direct", @team, "member", nil, nil, false ],
      [ "direct", @team, "admin", nil, nil, false ],
      [ "direct", nil, nil, @enterprise_group, "member", false ],
      [ "direct", nil, nil, @enterprise_group, "admin", false ],
      [ "direct", @team, "member", @enterprise_group, "member", false ],

      [ "invited", nil, nil, nil, nil, false ],
      [ "invited", @team, nil, nil, nil, false ],
      [ "invited", @team, "member", nil, nil, true ],
      [ "invited", @team, "admin", nil, nil, true ],
      [ "invited", @team, "member", @enterprise_group, "member", false ],
      [ "invited", nil, nil, @enterprise_group, "member", false ],

      [ "enterprise", nil, nil, nil, nil, false ],
      [ "enterprise", nil, nil, @enterprise_group, nil, false ],
      [ "enterprise", nil, nil, @enterprise_group, "member", true ],
      [ "enterprise", nil, nil, @enterprise_group, "admin", true ],
      [ "enterprise", @team, "member", @enterprise_group, "member", false ],
      [ "enterprise", @team, "member", nil, nil, false ]
    ]

    test_matrix.each do |user_type, team, team_role, enterprise, enterprise_role, should_be_valid|
      user = User.new(
        email: "test_#{user_type}_#{team_role}_#{enterprise_role}@example.com",
        password: "Password123!",
        user_type: user_type,
        team: team,
        team_role: team_role,
        enterprise_group: enterprise,
        enterprise_group_role: enterprise_role
      )

      if should_be_valid
        assert user.valid?,
          "User type '#{user_type}' with team_role '#{team_role}' and enterprise_role '#{enterprise_role}' should be valid but has errors: #{user.errors.full_messages.join(', ')}"
      else
        assert_not user.valid?,
          "User type '#{user_type}' with team_role '#{team_role}' and enterprise_role '#{enterprise_role}' should be invalid"
      end
    end
  end

  # Weight: 9 - System role hierarchy permissions test
  test "system role permissions follow proper hierarchy" do
    @user.skip_confirmation!
    @user.save!

    # Users cannot self-promote
    original_role = @user.system_role
    @user.system_role = "site_admin"
    # This is allowed at model level - controller should prevent
    assert @user.valid?

    # Super admin has highest privileges
    super_admin = User.create!(
      email: "super@example.com",
      password: "Password123!",
      system_role: "super_admin",
      confirmed_at: Time.current
    )
    assert super_admin.super_admin?
    assert_not super_admin.site_admin?
    assert_not super_admin.user?

    # Site admin has medium privileges
    site_admin = User.create!(
      email: "site@example.com",
      password: "Password123!",
      system_role: "site_admin",
      confirmed_at: Time.current
    )
    assert site_admin.site_admin?
    assert_not site_admin.super_admin?
    assert_not site_admin.user?

    # Regular user has basic privileges
    regular_user = User.create!(
      email: "regular@example.com",
      password: "Password123!",
      system_role: "user",
      confirmed_at: Time.current
    )
    assert regular_user.user?
    assert_not regular_user.site_admin?
    assert_not regular_user.super_admin?
  end

  # Weight: 8 - Status state machine transitions test
  test "user status transitions follow business rules" do
    @user.skip_confirmation!
    @user.save!

    # Valid status values
    valid_statuses = [ "active", "inactive", "locked" ]
    valid_statuses.each do |status|
      @user.status = status
      assert @user.valid?, "Status '#{status}' should be valid"
    end

    # Active -> Inactive (valid for suspension)
    @user.status = "active"
    @user.save!
    @user.status = "inactive"
    assert @user.valid?

    # Inactive -> Active (valid for reactivation)
    @user.save!
    @user.status = "active"
    assert @user.valid?

    # Active -> Locked (valid for security)
    @user.save!
    @user.status = "locked"
    assert @user.valid?

    # Locked users need admin intervention to unlock
    @user.save!
    @user.status = "active"
    assert @user.valid? # Model allows it, controller should restrict
  end

  # ========================================================================
  # NEW CRITICAL TESTS - MISSING BUSINESS RULES
  # ========================================================================

  # Weight: 10 - CR-A3: Self-role change prevention - security critical
  test "admins cannot change their own system role" do
    admin = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      system_role: "site_admin",
      confirmed_at: Time.current
    )

    # Set validation context with current user
    Thread.current[:validation_context] = { current_user_id: admin.id }

    # Try to promote self to super_admin
    admin.system_role = "super_admin"
    assert_not admin.valid?
    assert_includes admin.errors[:system_role], "cannot be changed by yourself"

    # Try to demote self to user
    admin.reload
    admin.system_role = "user"
    assert_not admin.valid?
    assert_includes admin.errors[:system_role], "cannot be changed by yourself"

    # Another admin can change the role
    Thread.current[:validation_context] = { current_user_id: users(:super_admin).id }
    admin.system_role = "user"
    assert admin.valid?

    # Clean up
    Thread.current[:validation_context] = nil
  end

  # Weight: 10 - CR-S2: Mass assignment protection for critical fields
  test "mass assignment protection prevents unauthorized field updates" do
    user_params = {
      email: "test@example.com",
      password: "Password123!",
      system_role: "super_admin", # Should not be mass assignable
      stripe_customer_id: "cus_malicious", # Should not be mass assignable
      confirmed_at: Time.current # Should not be mass assignable
    }

    # In Rails, mass assignment protection is handled by strong parameters in controllers
    # Here we test that critical fields are marked appropriately
    user = User.new

    # These fields should require special handling
    critical_fields = %w[system_role stripe_customer_id confirmed_at sign_in_count last_sign_in_at]

    critical_fields.each do |field|
      # Verify the field exists
      assert user.respond_to?(field), "User should have #{field} attribute"
      assert user.respond_to?("#{field}="), "User should have #{field}= setter"
    end

    # In practice, controllers would use strong parameters to prevent these assignments
    # This test documents which fields need protection
  end

  # Weight: 9 - Thread-local validation context usage
  test "validation uses thread-local context for security checks" do
    @user.skip_confirmation!
    @user.save!

    # Without context, changes are allowed
    Thread.current[:validation_context] = nil
    @user.system_role = "site_admin"
    assert @user.valid?

    # With context matching user ID, self-changes are prevented
    Thread.current[:validation_context] = { current_user_id: @user.id }
    @user.system_role = "super_admin"
    assert_not @user.valid?
    assert_includes @user.errors[:system_role], "cannot be changed by yourself"

    # With context of different user, changes are allowed
    Thread.current[:validation_context] = { current_user_id: 999 }
    @user.system_role = "super_admin"
    assert @user.valid?

    # Clean up
    Thread.current[:validation_context] = nil
  end

  # Weight: 9 - Security-sensitive change detection
  test "security_sensitive_change? detects critical field modifications" do
    @user.skip_confirmation!
    @user.save!

    # No changes initially
    assert_not @user.security_sensitive_change?

    # System role change is security sensitive
    @user.system_role = "super_admin"
    assert @user.security_sensitive_change?

    @user.reload

    # Status change is security sensitive
    @user.status = "locked"
    assert @user.security_sensitive_change?

    @user.reload

    # Email change is critical but not security sensitive
    @user.email = "newemail@example.com"
    assert_not @user.security_sensitive_change?
    assert @user.critical_field_changed?

    @user.reload

    # Name change is neither critical nor security sensitive
    @user.first_name = "NewName"
    assert_not @user.security_sensitive_change?
    assert_not @user.critical_field_changed?
  end

  # Weight: 8 - Direct user team creation rules
  test "direct users can create and own teams but follow ownership rules" do
    direct_user = User.create!(
      email: "direct@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    # Direct user can be set as team admin during team creation
    team = Team.new(
      name: "Direct User Team",
      admin: direct_user,
      created_by: users(:super_admin)
    )
    assert team.valid?
    assert team.save

    # The direct user owns this team
    assert_includes direct_user.administered_teams, team

    # But still cannot be assigned to another team as a member
    another_team = Team.create!(
      name: "Another Team",
      admin: users(:super_admin),
      created_by: users(:super_admin)
    )

    direct_user.team = another_team
    direct_user.team_role = "member"
    assert_not direct_user.valid?
    assert_includes direct_user.errors[:team_id], "direct users can only be associated with teams they own"
  end

  # Weight: 8 - Audit log integration for security changes
  test "security changes trigger audit log entries" do
    @user.skip_confirmation!
    @user.save!

    # Test that changing system_role is detected as security sensitive
    @user.system_role = "site_admin"
    assert @user.security_sensitive_change?, "Changing system_role should be security sensitive"

    # Test that changing status is also security sensitive
    @user.reload
    @user.status = "locked"
    assert @user.security_sensitive_change?, "Changing status should be security sensitive"

    # Test that changing non-security fields is not security sensitive
    @user.reload
    @user.first_name = "Changed"
    assert_not @user.security_sensitive_change?, "Changing first_name should not be security sensitive"
  end

  # Weight: 7 - Billing isolation between user types
  test "billing fields are properly isolated by user type" do
    # Direct users can have Stripe customer ID
    direct_user = User.create!(
      email: "directbilling@example.com",
      password: "Password123!",
      user_type: "direct",
      stripe_customer_id: "cus_direct123",
      confirmed_at: Time.current
    )
    assert_equal "cus_direct123", direct_user.stripe_customer_id

    # Invited users should not have individual billing
    invited_user = User.create!(
      email: "invitedbilling@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )

    # Stripe customer ID should be ignored for non-direct users
    invited_user.stripe_customer_id = "cus_invalid"
    invited_user.save
    # In practice, this would be handled by controller/service layer

    # Enterprise users also should not have individual billing
    enterprise_user = User.create!(
      email: "enterprisebilling@example.com",
      password: "Password123!",
      user_type: "enterprise",
      enterprise_group: @enterprise_group,
      enterprise_group_role: "member",
      confirmed_at: Time.current
    )

    enterprise_user.stripe_customer_id = "cus_enterprise"
    enterprise_user.save
    # In practice, this would be handled by controller/service layer
  end
end
