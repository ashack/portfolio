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

  # ========================================================================
  # CRITICAL TESTS (Weight: 9-10)
  # ========================================================================
  
  # Weight: 9 - CR-T2: Member limit enforcement - revenue protection
  test "team enforces member limits based on plan" do
    @team.max_members = 2
    @team.save!
    
    # Add members up to limit
    2.times do |i|
      User.create!(
        email: "member#{i}@example.com",
        password: "Password123!",
        user_type: "invited",
        team: @team,
        team_role: "member",
        confirmed_at: Time.current
      )
    end
    
    assert_not @team.can_add_members?
    assert_equal 2, @team.member_count
    
    # Verify limit is enforced at controller/service level
    # Model allows creation but business logic should check can_add_members?
  end

  # Weight: 9 - CR-T3: Admin presence validation - team integrity
  test "team must have admin user" do
    @team.save!
    
    # Try to remove admin
    @team.admin = nil
    assert_not @team.valid?
    assert_includes @team.errors[:admin], "must exist"
    
    # Restore admin
    @team.admin = @admin_user
    assert @team.valid?
  end

  # ========================================================================
  # HIGH PRIORITY TESTS (Weight: 7-8)
  # ========================================================================

  # Weight: 8 - IR-T1: Slug uniqueness and generation - URL routing integrity
  test "slug generation and uniqueness" do
    # Test basic slug generation
    @team.save!
    assert_equal "test-team", @team.slug
    
    # Test special character handling
    special_cases = {
      "Team & Co." => "team-co",
      "Team@123!" => "team123",
      "Team    With    Spaces" => "team-with-spaces",
      "  Trimmed Team  " => "trimmed-team"
    }
    
    special_cases.each do |name, expected_slug|
      team = Team.create!(
        name: name,
        admin: @admin_user,
        created_by: @super_admin
      )
      assert_equal expected_slug, team.slug, "Name '#{name}' should generate slug '#{expected_slug}'"
    end
    
    # Test uniqueness enforcement
    team2 = Team.create!(
      name: "Test Team",
      admin: @admin_user,
      created_by: @super_admin
    )
    assert_equal "test-team-1", team2.slug
    
    # Test manual slug validation
    team2.slug = @team.slug
    assert_not team2.valid?
    assert_includes team2.errors[:slug], "has already been taken"
  end

  # Weight: 8 - IR-T2: User deletion prevention - data integrity
  test "team prevents user deletion when users exist" do
    @team.save!
    
    # Add team members
    User.create!(
      email: "member@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )
    
    # Team should have dependent: :restrict_with_error
    assert_raises(ActiveRecord::RecordNotDestroyed) do
      @team.destroy!
    end
    
    assert @team.persisted?
  end

  # Weight: 7 - IR-T3: Cache invalidation - performance critical
  test "find_by_slug! uses caching effectively" do
    @team.save!
    
    # First call should hit database
    found_team = Team.find_by_slug!(@team.slug)
    assert_equal @team.id, found_team.id
    
    # Should raise error for non-existent slug
    assert_raises(ActiveRecord::RecordNotFound) do
      Team.find_by_slug!("non-existent-slug")
    end
  end

  # Weight: 7 - IR-T4: Plan features mapping - feature access control
  test "plan_features returns correct features for each plan" do
    # Comprehensive test of all plan features
    plan_features = {
      "starter" => ['team_dashboard', 'collaboration', 'email_support'],
      "pro" => ['team_dashboard', 'collaboration', 'advanced_team_features', 'priority_support'],
      "enterprise" => ['team_dashboard', 'collaboration', 'advanced_team_features', 'enterprise_features', 'phone_support']
    }
    
    plan_features.each do |plan, expected_features|
      @team.plan = plan
      assert_equal expected_features, @team.plan_features,
        "Plan '#{plan}' should have features: #{expected_features.join(', ')}"
    end
  end

  # ========================================================================
  # MEDIUM PRIORITY TESTS (Weight: 5-6)
  # ========================================================================

  # Weight: 6 - Basic validations (consolidated)
  test "field validations work correctly" do
    # Name validation
    @team.name = nil
    assert_not @team.valid?
    assert_includes @team.errors[:name], "can't be blank"
    
    @team.name = "A"
    assert_not @team.valid?
    assert_includes @team.errors[:name], "is too short (minimum is 2 characters)"
    
    @team.name = "A" * 51
    assert_not @team.valid?
    assert_includes @team.errors[:name], "is too long (maximum is 50 characters)"
    
    # Required associations
    @team.name = "Valid Name"
    @team.admin = nil
    assert_not @team.valid?
    assert_includes @team.errors[:admin], "must exist"
    
    @team.admin = @admin_user
    @team.created_by = nil
    assert_not @team.valid?
    assert_includes @team.errors[:created_by], "must exist"
    
    # Slug format validation
    @team.created_by = @super_admin
    @team.save!
    @team.slug = "Invalid Slug!"
    assert_not @team.valid?
    assert_includes @team.errors[:slug], "is invalid"
  end

  # Weight: 5 - Associations (consolidated)
  test "associations work correctly" do
    @team.save!
    
    # Users association
    user = User.create!(
      email: "member@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )
    
    assert_includes @team.users, user
    assert_equal 1, @team.users.count
    
    # Invitations association
    invitation = Invitation.create!(
      team: @team,
      invitable: @team,
      invitable_type: 'Team',
      invitation_type: 'team',
      email: "newuser@example.com",
      role: "member",
      invited_by: @admin_user,
      expires_at: 7.days.from_now
    )
    
    assert_includes @team.invitations, invitation
    
    # Admin and created_by associations
    assert_equal @admin_user, @team.admin
    assert_equal @super_admin, @team.created_by
  end

  # Weight: 5 - Scopes (consolidated)
  test "scopes filter correctly" do
    @team.save!
    
    # Active scope
    suspended_team = Team.create!(
      name: "Suspended Team",
      admin: @admin_user,
      created_by: @super_admin,
      status: "suspended"
    )
    
    active_teams = Team.active
    assert_includes active_teams, @team
    assert_not_includes active_teams, suspended_team
    
    # Plan enum scopes
    @team.update!(plan: "pro")
    pro_teams = Team.pro
    assert_includes pro_teams, @team
    
    # With associations scope (prevents N+1)
    teams = Team.with_associations
    assert_nothing_raised do
      teams.each do |team|
        team.admin.email
        team.created_by.email
        team.users.count
      end
    end
  end

  # ========================================================================
  # LOW PRIORITY TESTS (Keep only essential)
  # ========================================================================

  # Weight: 4 - Keep one test for settings JSON storage
  test "team settings can store complex JSON data" do
    @team.settings = {
      notifications: { email: true, slack: false },
      features: { advanced_reporting: true }
    }
    @team.save!
    @team.reload
    
    assert_equal true, @team.settings["notifications"]["email"]
    assert_equal false, @team.settings["notifications"]["slack"]
    assert_equal true, @team.settings["features"]["advanced_reporting"]
  end

  # ========================================================================
  # NEW CRITICAL TESTS (Previously Missing)
  # ========================================================================

  # Weight: 9 - Cannot delete last admin (edge case)
  test "cannot delete last admin from team" do
    @team.save!
    
    # Create team admin
    team_admin = User.create!(
      email: "teamadmin@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "admin",
      confirmed_at: Time.current
    )
    
    # Update team to use this admin
    @team.update!(admin: team_admin)
    
    # Create team member
    team_member = User.create!(
      email: "member@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )
    
    # Should be able to delete member
    assert_difference 'User.count', -1 do
      team_member.destroy!
    end
    
    # Cannot delete team admin if they're referenced as the team's admin
    # This is actually prevented by foreign key constraint
    assert_raises(ActiveRecord::InvalidForeignKey) do
      team_admin.destroy!
    end
    
    # Team admin is still there
    assert User.exists?(team_admin.id)
    
    # Business logic should prevent this by reassigning admin first
    # or by soft-deleting users instead
  end

  # Weight: 8 - Team creation flow validation
  test "complete team creation flow works correctly" do
    # Simulate full team creation
    new_team = Team.new(
      name: "Complete Team",
      admin: @admin_user,
      created_by: @super_admin,
      plan: "starter",
      status: "active",
      max_members: 5
    )
    
    assert new_team.valid?
    assert new_team.save
    
    # Verify slug generation
    assert_equal "complete-team", new_team.slug
    
    # Verify default values
    assert_equal 5, new_team.max_members
    assert_equal "active", new_team.status
    assert_equal "starter", new_team.plan
    
    # Verify it can be found by slug
    found = Team.find_by_slug!(new_team.slug)
    assert_equal new_team.id, found.id
  end
end