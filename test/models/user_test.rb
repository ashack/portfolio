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

    # Create a team for invited user
    team = Team.create!(
      name: "Test Team",
      slug: "test-team",
      admin_id: 1,
      created_by_id: 1
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
end
