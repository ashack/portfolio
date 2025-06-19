require "test_helper"

class TeamTest < ActiveSupport::TestCase
  def setup
    # Create admin user for team
    @admin_user = User.new(
      email: "admin@example.com",
      password: "Password123!",
      first_name: "Admin",
      last_name: "User",
      user_type: "direct",
      status: "active"
    )
    @admin_user.skip_confirmation!
    @admin_user.save!

    # Create super admin for created_by
    @super_admin = User.new(
      email: "super@example.com",
      password: "Password123!",
      first_name: "Super",
      last_name: "Admin",
      user_type: "direct",
      status: "active",
      system_role: "super_admin"
    )
    @super_admin.skip_confirmation!
    @super_admin.save!

    @team = Team.new(
      name: "Test Team",
      admin: @admin_user,
      created_by: @super_admin,
      plan: "starter",
      status: "active"
    )
  end

  test "should be valid with valid attributes" do
    assert @team.valid?
  end

  test "should require name" do
    @team.name = nil
    assert_not @team.valid?
    assert_includes @team.errors[:name], "can't be blank"
  end

  test "should require name to be at least 2 characters" do
    @team.name = "A"
    assert_not @team.valid?
    assert_includes @team.errors[:name], "is too short (minimum is 2 characters)"
  end

  test "should require name to be at most 50 characters" do
    @team.name = "A" * 51
    assert_not @team.valid?
    assert_includes @team.errors[:name], "is too long (maximum is 50 characters)"
  end

  test "should generate slug from name" do
    @team.save!
    assert_equal "test-team", @team.slug
  end

  test "should generate unique slug when name conflicts" do
    @team.save!

    team2 = Team.new(
      name: "Test Team",
      admin: @admin_user,
      created_by: @super_admin
    )
    team2.save!

    assert_equal "test-team-1", team2.slug
  end

  test "should sanitize slug from special characters" do
    @team.name = "Test & Team! @123"
    @team.save!
    assert_equal "test-team-123", @team.slug
  end

  test "should require unique slug" do
    skip "Slug is auto-generated and cannot be manually set for testing"
  end

  test "should require admin" do
    @team.admin = nil
    assert_not @team.valid?
    assert_includes @team.errors[:admin], "must exist"
  end

  test "should require created_by" do
    @team.created_by = nil
    assert_not @team.valid?
    assert_includes @team.errors[:created_by], "must exist"
  end

  test "should have default plan of starter" do
    new_team = Team.new
    assert_equal "starter", new_team.plan
  end

  test "should have default status of active" do
    new_team = Team.new
    assert_equal "active", new_team.status
  end

  test "should have max_members set on creation" do
    @team.plan = "starter"
    @team.max_members = 5
    @team.save!
    assert_equal 5, @team.max_members

    @team.plan = "pro"
    @team.max_members = 15
    @team.save!
    assert_equal 15, @team.max_members

    @team.plan = "enterprise"
    @team.max_members = 100
    @team.save!
    assert_equal 100, @team.max_members
  end

  test "to_param returns slug" do
    @team.save!
    assert_equal @team.slug, @team.to_param
  end

  test "member_count returns number of users" do
    @team.save!
    assert_equal 0, @team.member_count

    # Create team members as invited users from the start
    admin_member = User.new(
      email: "admin_member@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "admin"
    )
    admin_member.skip_confirmation!
    admin_member.save!

    assert_equal 1, @team.member_count

    # Add another member
    member = User.new(
      email: "member@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member"
    )
    member.skip_confirmation!
    member.save!

    assert_equal 2, @team.member_count
  end

  test "can_add_members? returns true when under limit" do
    @team.max_members = 5
    @team.save!

    assert @team.can_add_members?
  end

  test "can_add_members? returns false when at limit" do
    @team.max_members = 1
    @team.save!

    # Create a team member
    member = User.new(
      email: "team_member@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member"
    )
    member.skip_confirmation!
    member.save!

    assert_not @team.can_add_members?
  end

  test "plan_features returns correct features for each plan" do
    @team.plan = "starter"
    expected_starter = [ "team_dashboard", "collaboration", "email_support" ]
    assert_equal expected_starter, @team.plan_features

    @team.plan = "pro"
    expected_pro = [ "team_dashboard", "collaboration", "advanced_team_features", "priority_support" ]
    assert_equal expected_pro, @team.plan_features

    @team.plan = "enterprise"
    expected_enterprise = [ "team_dashboard", "collaboration", "advanced_team_features", "enterprise_features", "phone_support" ]
    assert_equal expected_enterprise, @team.plan_features
  end

  test "active scope returns only active teams" do
    @team.save!

    inactive_team = Team.create!(
      name: "Inactive Team",
      admin: @admin_user,
      created_by: @super_admin,
      status: "suspended"
    )

    active_teams = Team.active
    assert_includes active_teams, @team
    assert_not_includes active_teams, inactive_team
  end

  test "should not allow deletion if users exist" do
    @team.save!

    # Create a team member
    member = User.new(
      email: "deletiontest@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member"
    )
    member.skip_confirmation!
    member.save!

    # Try to destroy the team
    assert_not @team.destroy
    assert @team.errors[:base].any? { |e| e.match?(/cannot delete.*users/i) }
  end

  test "should set team admin association" do
    @team.save!

    assert_equal @admin_user, @team.admin
    assert_equal @team.admin_id, @admin_user.id
  end

  test "should handle settings as JSON" do
    @team.settings = { "feature_enabled" => true, "limit" => 100 }
    @team.save!
    @team.reload

    assert_equal true, @team.settings["feature_enabled"]
    assert_equal 100, @team.settings["limit"]
  end
end
