require "test_helper"

class UserValidationsTest < ActiveSupport::TestCase
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

  # Password complexity validation tests
  test "password must be at least 8 characters" do
    @user.password = "Pass1!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must be at least 8 characters long"
  end

  test "password must include uppercase letter" do
    @user.password = "password123!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one uppercase letter"
  end

  test "password must include lowercase letter" do
    @user.password = "PASSWORD123!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one lowercase letter"
  end

  test "password must include number" do
    @user.password = "Password!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one number"
  end

  test "password must include special character" do
    @user.password = "Password123"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one special character"
  end

  test "password validation shows all errors at once" do
    @user.password = "pass"
    assert_not @user.valid?

    password_errors = @user.errors[:password]
    assert password_errors.any? { |e| e.include?("at least 8 characters") }
    assert password_errors.any? { |e| e.include?("uppercase letter") }
    assert password_errors.any? { |e| e.include?("number") }
    assert password_errors.any? { |e| e.include?("special character") }
  end

  test "password validation accepts strong passwords" do
    strong_passwords = [
      "Password123!",
      "MyStr0ng!Pass",
      "Test@123Pass",
      "P@ssw0rd!",
      "Aa1!aaaa",
      "PASS@word123"
    ]

    strong_passwords.each do |password|
      @user.password = password
      assert @user.valid?, "Password '#{password}' should be valid"
    end
  end

  test "password validation is skipped when password not changed" do
    @user.skip_confirmation!
    @user.save!

    # Update other attributes without changing password
    @user.first_name = "Updated"
    assert @user.valid?
  end

  # Email validation with pending invitations
  test "email cannot match pending invitation" do
    # Create admin user first
    admin = User.create!(
      email: "teamadmin@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    # Create a team and invitation
    team = Team.create!(
      name: "Test Team",
      admin: admin,
      created_by: admin
    )

    Invitation.create!(
      team: team,
      email: "invited@example.com",
      invited_by: admin,
      token: SecureRandom.hex,
      expires_at: 7.days.from_now
    )

    # Try to create user with same email
    @user.email = "invited@example.com"
    assert_not @user.valid?
    assert @user.errors[:email].any? { |e| e.include?("conflicts with pending team invitation") }
  end

  test "email can match expired invitation" do
    # Create admin user first
    admin = User.create!(
      email: "teamadmin2@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    team = Team.create!(
      name: "Test Team",
      admin: admin,
      created_by: admin
    )

    # Create invitation and then update to make it expired
    invitation = Invitation.create!(
      team: team,
      email: "expired@example.com",
      invited_by: admin
    )

    # Update to make it expired (bypass callbacks)
    invitation.update_column(:expires_at, 2.days.ago)

    # Verify the invitation is expired and would not be returned by active scope
    assert invitation.reload.expired?, "Invitation should be expired"
    assert_nil Invitation.pending.active.find_by(email: "expired@example.com"),
      "Expired invitation should not be in pending.active scope"

    @user.email = "expired@example.com"
    assert @user.valid?, "User should be valid when email matches expired invitation"
  end

  test "email can match accepted invitation" do
    # Create admin user first
    admin = User.create!(
      email: "teamadmin3@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    team = Team.create!(
      name: "Test Team",
      admin: admin,
      created_by: admin
    )

    # Create accepted invitation
    invitation = Invitation.create!(
      team: team,
      email: "accepted@example.com",
      invited_by: admin,
      token: SecureRandom.hex,
      expires_at: 7.days.from_now,
      accepted_at: 1.hour.ago
    )

    @user.email = "accepted@example.com"
    assert @user.valid?
  end

  # User type change validation
  test "user_type cannot be changed after creation" do
    @user.skip_confirmation!
    @user.save!

    @user.user_type = "invited"
    assert_not @user.valid?
    assert @user.errors[:user_type].any? { |e| e.include?("cannot be changed from 'direct' to 'invited'") }
  end

  test "user_type can be set during creation" do
    new_user = User.new(
      email: "new@example.com",
      password: "Password123!",
      user_type: "invited",
      team_id: 1,
      team_role: "member"
    )

    # Should not have user_type change error
    new_user.valid?
    assert_not new_user.errors[:user_type].any? { |e| e.include?("cannot be changed") }
  end

  # Team constraint validations
  test "direct user cannot have team_id" do
    @user.user_type = "direct"
    @user.team_id = 1

    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "cannot be set for direct users"
  end

  test "direct user cannot have team_role" do
    @user.user_type = "direct"
    @user.team_role = "member"

    assert_not @user.valid?
    assert_includes @user.errors[:team_role], "cannot be set for direct users"
  end

  test "direct user validation prevents both team fields" do
    @user.user_type = "direct"
    @user.team_id = 1
    @user.team_role = "member"

    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "cannot be set for direct users"
    assert_includes @user.errors[:team_role], "cannot be set for direct users"
  end

  test "invited user must have team_id" do
    @user.user_type = "invited"
    @user.team_role = "member"

    assert_not @user.valid?
    assert_includes @user.errors[:team_id], "is required for team members"
  end

  test "invited user must have team_role" do
    @user.user_type = "invited"
    @user.team_id = 1

    assert_not @user.valid?
    assert_includes @user.errors[:team_role], "is required for team members"
  end

  # Team role transition validations
  test "team admin cannot be demoted if only admin" do
    # Create super admin first
    super_admin = User.create!(
      email: "superadmin2@example.com",
      password: "Password123!",
      user_type: "direct",
      system_role: "super_admin",
      confirmed_at: Time.current
    )

    # Create team
    team = Team.create!(
      name: "Test Team",
      admin: super_admin,
      created_by: super_admin
    )

    # Create team admin
    admin = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      user_type: "invited",
      team: team,
      team_role: "admin",
      confirmed_at: Time.current
    )

    # Update team to use the invited admin
    team.update!(admin: admin)

    # Try to demote to member
    admin.team_role = "member"
    assert_not admin.valid?
    assert admin.errors[:team_role].any? { |e| e.include?("team must have at least one admin") }
  end

  test "team admin can be demoted if another admin exists" do
    # Create super admin user first
    super_admin = User.create!(
      email: "superadmin@example.com",
      password: "Password123!",
      user_type: "direct",
      system_role: "super_admin",
      confirmed_at: Time.current
    )

    # Create team
    team = Team.create!(
      name: "Test Team",
      admin: super_admin,
      created_by: super_admin
    )

    # Create two admins
    admin1 = User.create!(
      email: "admin1@example.com",
      password: "Password123!",
      user_type: "invited",
      team: team,
      team_role: "admin",
      confirmed_at: Time.current
    )

    admin2 = User.create!(
      email: "admin2@example.com",
      password: "Password123!",
      user_type: "invited",
      team: team,
      team_role: "admin",
      confirmed_at: Time.current
    )

    # Update team admin
    team.update!(admin: admin1)

    # Admin2 can be demoted
    admin2.team_role = "member"
    assert admin2.valid?
  end

  # System role validation
  test "system_role must be valid enum value" do
    assert_raises(ArgumentError) do
      @user.system_role = "invalid_role"
    end
  end

  test "system_role defaults to user" do
    new_user = User.new
    assert_equal "user", new_user.system_role
  end

  # Status validation
  test "status must be valid enum value" do
    assert_raises(ArgumentError) do
      @user.status = "invalid_status"
    end
  end

  test "status defaults to active" do
    new_user = User.new
    assert_equal "active", new_user.status
  end

  # Email format validation edge cases
  test "email validation accepts valid formats" do
    valid_emails = [
      "user@example.com",
      "user.name@example.com",
      "user+tag@example.co.uk",
      "user_name@example-domain.com",
      "123@example.com",
      "a@b.co"
    ]

    valid_emails.each do |email|
      @user.email = email
      assert @user.valid?, "Email '#{email}' should be valid"
    end
  end

  test "email validation rejects invalid formats" do
    invalid_emails = [
      "plaintext",
      "@example.com",
      "user@",
      "user name@example.com",
      "user@.com"
    ]

    invalid_emails.each do |email|
      @user.email = email
      assert_not @user.valid?, "Email '#{email}' should be invalid"
      assert_includes @user.errors[:email], "must be a valid email address"
    end
  end

  # Presence validations
  test "user_type is required" do
    @user.user_type = nil
    assert_not @user.valid?
    assert_includes @user.errors[:user_type], "can't be blank"
  end

  test "status is required" do
    @user.status = nil
    assert_not @user.valid?
    assert_includes @user.errors[:status], "can't be blank"
  end

  # Complex validation scenarios
  test "multiple validation errors are collected" do
    @user.email = "invalid"
    @user.password = "weak"
    @user.first_name = "Name123"
    @user.user_type = nil

    assert_not @user.valid?

    assert @user.errors[:email].any?
    assert @user.errors[:password].any?
    assert @user.errors[:first_name].any?
    assert @user.errors[:user_type].any?
  end

  test "validation context affects which validations run" do
    # Create a user that would fail on :accept context
    @user.skip_confirmation!
    @user.save!

    # This would fail if we were checking pending invitations on update
    assert @user.valid?
  end
end
