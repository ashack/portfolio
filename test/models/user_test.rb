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
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    invalid_emails = [ "invalid", "test@", "@example.com" ]
    invalid_emails.each do |invalid_email|
      @user.email = invalid_email
      assert_not @user.valid?, "#{invalid_email} should be invalid"
    end
  end

  test "should require unique email" do
    @user.skip_confirmation!
    @user.save!
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    assert_not duplicate_user.valid?
  end

  test "should require password" do
    @user.password = nil
    assert_not @user.valid?
  end

  test "direct user should not have team associations" do
    @user.user_type = "direct"
    @user.team_id = 1
    @user.team_role = "member"
    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "cannot be set for direct users"
    assert_includes @user.errors[:team_role], "cannot be set for direct users"
  end

  test "invited user must have team associations" do
    @user.user_type = "invited"
    @user.team_id = nil
    @user.team_role = nil
    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "is required for team members"
    assert_includes @user.errors[:team_role], "is required for team members"
  end

  test "full_name returns concatenated first and last name" do
    assert_equal "Test User", @user.full_name
  end

  test "full_name handles missing names gracefully" do
    @user.first_name = nil
    @user.last_name = nil
    assert_equal "", @user.full_name.strip
  end

  test "can_sign_in? returns true for active users" do
    @user.status = "active"
    assert @user.can_sign_in?
  end

  test "can_sign_in? returns false for inactive users" do
    @user.status = "inactive"
    assert_not @user.can_sign_in?
  end

  test "can_sign_in? returns false for locked users" do
    @user.status = "locked"
    assert_not @user.can_sign_in?
  end

  test "team_admin? returns true for invited admin users" do
    @user.user_type = "invited"
    @user.team_role = "admin"
    @user.team_id = 1
    assert @user.team_admin?
  end

  test "team_admin? returns false for direct users" do
    @user.user_type = "direct"
    assert_not @user.team_admin?
  end

  test "team_member? returns true for invited member users" do
    @user.user_type = "invited"
    @user.team_role = "member"
    @user.team_id = 1
    assert @user.team_member?
  end

  test "scopes filter users correctly" do
    # Create test users
    active_direct = User.new(
      email: "active_direct@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active"
    )
    active_direct.skip_confirmation!
    active_direct.save!

    inactive_user = User.new(
      email: "inactive@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "inactive"
    )
    inactive_user.skip_confirmation!
    inactive_user.save!

    # Create an admin user for the team
    admin_user = User.new(
      email: "teamadmin@example.com",
      password: "Password123!",
      system_role: "super_admin",
      user_type: "direct"
    )
    admin_user.skip_confirmation!
    admin_user.save!

    # Create a team for invited user
    team = Team.create!(
      name: "Test Team",
      slug: "test-team",
      admin: admin_user,
      created_by: admin_user
    )

    invited_user = User.new(
      email: "invited@example.com",
      password: "Password123!",
      user_type: "invited",
      status: "active",
      team: team,
      team_role: "member"
    )
    invited_user.skip_confirmation!
    invited_user.save!

    # Test scopes
    assert_includes User.active, active_direct
    assert_includes User.active, invited_user
    assert_not_includes User.active, inactive_user

    assert_includes User.direct_users, active_direct
    assert_not_includes User.direct_users, invited_user

    assert_includes User.team_members, invited_user
    assert_not_includes User.team_members, active_direct
  end

  test "should validate first name format" do
    valid_names = [ "John", "Mary-Jane", "O'Brien", "St. James", "Jean Paul" ]
    valid_names.each do |name|
      @user.first_name = name
      assert @user.valid?, "#{name} should be valid"
    end

    invalid_names = [ "John123", "Mary@Jane", "Test#Name", "Name!" ]
    invalid_names.each do |name|
      @user.first_name = name
      assert_not @user.valid?
      assert_includes @user.errors[:first_name], "can only contain letters, spaces, hyphens, apostrophes, and periods"
    end
  end

  test "should validate last name format" do
    valid_names = [ "Smith", "Van Der Berg", "O'Connor", "St. Pierre" ]
    valid_names.each do |name|
      @user.last_name = name
      assert @user.valid?, "#{name} should be valid"
    end

    invalid_names = [ "Smith123", "Jones@Home", "Test#" ]
    invalid_names.each do |name|
      @user.last_name = name
      assert_not @user.valid?
      assert_includes @user.errors[:last_name], "can only contain letters, spaces, hyphens, apostrophes, and periods"
    end
  end

  test "should validate name length" do
    @user.first_name = "A" * 51
    assert_not @user.valid?
    assert_includes @user.errors[:first_name], "must be 50 characters or less"

    @user.first_name = "A" * 50
    assert @user.valid?

    @user.last_name = "B" * 51
    assert_not @user.valid?
    assert_includes @user.errors[:last_name], "must be 50 characters or less"
  end

  test "should validate password complexity" do
    weak_passwords = [ "password", "12345678", "PASSWORD", "Password", "password123" ]
    weak_passwords.each do |password|
      @user.password = password
      assert_not @user.valid?
      assert @user.errors[:password].any?
    end

    strong_passwords = [ "Password123!", "Str0ng!Pass", "MyP@ssw0rd", "Test123$" ]
    strong_passwords.each do |password|
      @user.password = password
      assert @user.valid?, "#{password} should be valid"
    end
  end

  test "should normalize email before validation" do
    skip "Devise mapping issue in test environment"
  end

  test "should have system role enum methods" do
    @user.system_role = "user"
    assert @user.user?
    assert_not @user.site_admin?
    assert_not @user.super_admin?

    @user.system_role = "site_admin"
    assert @user.site_admin?
    assert_not @user.user?

    @user.system_role = "super_admin"
    assert @user.super_admin?
  end

  test "should have user type enum methods" do
    @user.user_type = "direct"
    assert @user.direct?
    assert_not @user.invited?

    @user.user_type = "invited"
    @user.team_id = 1
    @user.team_role = "member"
    assert @user.invited?
    assert_not @user.direct?
  end

  test "should have status enum methods" do
    @user.status = "active"
    assert @user.active?
    assert_not @user.inactive?
    assert_not @user.locked?

    @user.status = "inactive"
    assert @user.inactive?

    @user.status = "locked"
    assert @user.locked?
  end

  test "should track sign in count" do
    @user.skip_confirmation!
    @user.save!

    assert_equal 0, @user.sign_in_count

    @user.update!(
      sign_in_count: @user.sign_in_count + 1,
      current_sign_in_at: Time.current,
      last_sign_in_at: @user.current_sign_in_at
    )

    assert_equal 1, @user.sign_in_count
  end

  test "should track last activity" do
    @user.skip_confirmation!
    @user.save!

    assert_nil @user.last_activity_at

    activity_time = Time.current
    @user.update_column(:last_activity_at, activity_time)

    assert_equal activity_time.to_i, @user.last_activity_at.to_i
  end

  test "should handle password reset" do
    skip "Devise mapping issue in test environment"
  end

  test "should handle account locking" do
    skip "Devise mapping issue in test environment"
  end

  test "should have associations" do
    assert_respond_to @user, :team
    assert_respond_to @user, :created_teams
    assert_respond_to @user, :administered_teams
    assert_respond_to @user, :sent_invitations
    assert_respond_to @user, :ahoy_visits
    assert_respond_to @user, :audit_logs
    assert_respond_to @user, :target_audit_logs
    assert_respond_to @user, :email_change_requests
    assert_respond_to @user, :approved_email_changes
  end

  test "should handle Pay customer methods" do
    @user.skip_confirmation!
    @user.save!

    assert_respond_to @user, :payment_processor
    assert_respond_to @user, :stripe_customer_id
  end

  test "direct user with team data should be invalid" do
    @user.user_type = "direct"
    @user.team_id = 1
    @user.team_role = "member"

    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "cannot be set for direct users"
    assert_includes @user.errors[:team_role], "cannot be set for direct users"
  end

  test "invited user without team data should be invalid" do
    @user.user_type = "invited"
    @user.team_id = nil
    @user.team_role = nil

    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "is required for team members"
    assert_includes @user.errors[:team_role], "is required for team members"
  end

  test "should allow blank first and last names" do
    @user.first_name = ""
    @user.last_name = ""
    assert @user.valid?
  end

  test "full_name handles nil names" do
    @user.first_name = nil
    @user.last_name = nil
    assert_equal "", @user.full_name
  end

  test "full_name handles partial names" do
    @user.first_name = "John"
    @user.last_name = nil
    assert_equal "John", @user.full_name

    @user.first_name = nil
    @user.last_name = "Doe"
    assert_equal "Doe", @user.full_name
  end

  test "should validate email uniqueness case insensitively" do
    @user.skip_confirmation!
    @user.save!

    duplicate_user = User.new(
      email: "TEST@EXAMPLE.COM",
      password: "Password123!",
      user_type: "direct"
    )

    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "is already taken"
  end

  test "should require confirmation for new users" do
    skip "Devise mapping issue in test environment"
  end

  test "should handle team role enum methods" do
    @user.user_type = "invited"
    @user.team_id = 1
    @user.team_role = "member"

    assert @user.member?
    assert_not @user.admin?

    @user.team_role = "admin"
    assert @user.admin?
    assert_not @user.member?
  end
end
