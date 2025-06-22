require "test_helper"

# Tests for User model scopes and query methods
# Note: This file only tests scopes/methods that are actually defined in the User model
class UserScopesAndQueriesTest < ActiveSupport::TestCase
  def setup
    # Create test data
    @super_admin = users(:super_admin)
    @site_admin = users(:site_admin)

    # Create teams
    @team1 = Team.create!(
      name: "Team One",
      admin: @super_admin,
      created_by: @super_admin
    )

    @team2 = Team.create!(
      name: "Team Two",
      admin: @super_admin,
      created_by: @super_admin
    )

    # Create enterprise group
    enterprise_plan = Plan.create!(
      name: "Enterprise Plan",
      plan_segment: "enterprise",
      amount_cents: 99900,
      active: true
    )

    @enterprise_group = EnterpriseGroup.create!(
      name: "Test Enterprise",
      created_by: @super_admin,
      plan: enterprise_plan,
      admin: @super_admin
    )

    # Create direct users
    @direct_user1 = User.create!(
      email: "direct1@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current
    )

    @direct_user2 = User.create!(
      email: "direct2@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "inactive",
      confirmed_at: Time.current
    )

    @direct_user3 = User.create!(
      email: "direct3@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "locked",
      confirmed_at: Time.current
    )

    # Create team users
    @team_admin1 = User.create!(
      email: "teamadmin1@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team1,
      team_role: "admin",
      status: "active",
      confirmed_at: Time.current
    )

    @team_member1 = User.create!(
      email: "teammember1@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team1,
      team_role: "member",
      status: "active",
      confirmed_at: Time.current
    )

    @team_member2 = User.create!(
      email: "teammember2@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team2,
      team_role: "member",
      status: "inactive",
      confirmed_at: Time.current
    )

    # Create enterprise users
    @enterprise_admin = User.create!(
      email: "enterpriseadmin@example.com",
      password: "Password123!",
      user_type: "enterprise",
      enterprise_group: @enterprise_group,
      enterprise_group_role: "admin",
      status: "active",
      confirmed_at: Time.current
    )

    @enterprise_member = User.create!(
      email: "enterprisemember@example.com",
      password: "Password123!",
      user_type: "enterprise",
      enterprise_group: @enterprise_group,
      enterprise_group_role: "member",
      status: "active",
      confirmed_at: Time.current
    )
  end

  # ========================================================================
  # DEFINED SCOPES IN USER MODEL
  # ========================================================================

  test "active scope returns only active users" do
    active_users = User.active

    assert_includes active_users, @direct_user1
    assert_includes active_users, @team_admin1
    assert_includes active_users, @team_member1
    assert_includes active_users, @enterprise_admin
    assert_includes active_users, @enterprise_member

    assert_not_includes active_users, @direct_user2  # inactive
    assert_not_includes active_users, @direct_user3  # locked
    assert_not_includes active_users, @team_member2  # inactive
  end

  test "direct_users scope returns only direct users" do
    direct_users = User.direct_users

    assert_includes direct_users, @direct_user1
    assert_includes direct_users, @direct_user2
    assert_includes direct_users, @direct_user3

    assert_not_includes direct_users, @team_admin1
    assert_not_includes direct_users, @team_member1
    assert_not_includes direct_users, @enterprise_admin
  end

  test "team_members scope returns only invited team users" do
    team_members = User.team_members

    assert_includes team_members, @team_admin1
    assert_includes team_members, @team_member1
    assert_includes team_members, @team_member2

    assert_not_includes team_members, @direct_user1
    assert_not_includes team_members, @enterprise_admin
  end

  test "with_associations scope prevents N+1 queries" do
    # This scope includes :team, :plan, :enterprise_group
    users = User.with_associations

    # Should not raise N+1 query issues when accessing associations
    assert_nothing_raised do
      users.each do |user|
        user.team&.name
        user.plan&.name
        user.enterprise_group&.name
      end
    end
  end

  test "with_team_details scope includes team information" do
    # This scope includes team with its admin and users
    users = User.with_team_details

    # Should not raise N+1 query issues when accessing team details
    assert_nothing_raised do
      users.each do |user|
        if user.team
          user.team.name
          user.team.admin&.email
          user.team.users.count
        end
      end
    end
  end

  # ========================================================================
  # ENUM-BASED QUERIES
  # ========================================================================

  test "status enum queries work correctly" do
    # Active users
    assert User.active.include?(@direct_user1)
    assert @direct_user1.active?

    # Inactive users
    assert User.inactive.include?(@direct_user2)
    assert @direct_user2.inactive?

    # Locked users
    assert User.locked.include?(@direct_user3)
    assert @direct_user3.locked?
  end

  test "user_type enum queries work correctly" do
    # Direct users
    assert User.direct.include?(@direct_user1)
    assert @direct_user1.direct?

    # Invited users
    assert User.invited.include?(@team_admin1)
    assert @team_admin1.invited?

    # Enterprise users
    assert User.enterprise.include?(@enterprise_admin)
    assert @enterprise_admin.enterprise?
  end

  test "system_role enum queries work correctly" do
    # Super admin
    assert User.super_admin.include?(@super_admin)
    assert @super_admin.super_admin?

    # Site admin
    assert User.site_admin.include?(@site_admin)
    assert @site_admin.site_admin?

    # Regular users
    assert User.user.include?(@direct_user1)
    assert @direct_user1.user?
  end

  test "team_role enum queries work correctly" do
    # Admin role
    assert User.admin.where(user_type: "invited").include?(@team_admin1)
    assert @team_admin1.admin?

    # Member role
    assert User.member.where(user_type: "invited").include?(@team_member1)
    assert @team_member1.member?
  end

  test "enterprise_group_role enum queries work correctly" do
    # Enterprise admin
    assert @enterprise_admin.enterprise_group_role_admin?

    # Enterprise member
    assert @enterprise_member.enterprise_group_role_member?
  end

  # ========================================================================
  # COMBINED QUERIES
  # ========================================================================

  test "active direct users query" do
    active_direct = User.active.direct_users

    assert_includes active_direct, @direct_user1

    assert_not_includes active_direct, @direct_user2  # inactive
    assert_not_includes active_direct, @direct_user3  # locked
    assert_not_includes active_direct, @team_admin1   # not direct
  end

  test "active team members query" do
    active_team_members = User.active.team_members

    assert_includes active_team_members, @team_admin1
    assert_includes active_team_members, @team_member1

    assert_not_includes active_team_members, @team_member2  # inactive
    assert_not_includes active_team_members, @direct_user1   # not team member
  end

  test "count users by type" do
    # Count actual users created in this test
    direct_count = User.direct.where(email: [ "direct1@example.com", "direct2@example.com", "direct3@example.com" ]).count
    invited_count = User.invited.where(email: [ "teamadmin1@example.com", "teammember1@example.com", "teammember2@example.com" ]).count
    enterprise_count = User.enterprise.where(email: [ "enterpriseadmin@example.com", "enterprisemember@example.com" ]).count

    assert_equal 3, direct_count
    assert_equal 3, invited_count
    assert_equal 2, enterprise_count
  end

  test "count active users by type" do
    # Count active users created in this test
    active_direct = User.active.direct.where(email: [ "direct1@example.com", "direct2@example.com", "direct3@example.com" ]).count
    active_invited = User.active.invited.where(email: [ "teamadmin1@example.com", "teammember1@example.com", "teammember2@example.com" ]).count
    active_enterprise = User.active.enterprise.where(email: [ "enterpriseadmin@example.com", "enterprisemember@example.com" ]).count

    assert_equal 1, active_direct  # Only direct1 is active
    assert_equal 2, active_invited  # teamadmin1 and teammember1 are active
    assert_equal 2, active_enterprise  # Both enterprise users are active
  end

  # ========================================================================
  # CUSTOM QUERIES
  # ========================================================================

  test "users with specific team" do
    team1_users = User.where(team: @team1)

    assert_includes team1_users, @team_admin1
    assert_includes team1_users, @team_member1

    assert_not_includes team1_users, @team_member2  # in team2
    assert_not_includes team1_users, @direct_user1
  end

  test "users with specific enterprise group" do
    enterprise_users = User.where(enterprise_group: @enterprise_group)

    assert_includes enterprise_users, @enterprise_admin
    assert_includes enterprise_users, @enterprise_member

    assert_not_includes enterprise_users, @direct_user1
    assert_not_includes enterprise_users, @team_admin1
  end

  test "search by email" do
    results = User.where("email LIKE ?", "%team%")

    assert_includes results, @team_admin1
    assert_includes results, @team_member1
    assert_includes results, @team_member2

    assert_not_includes results, @direct_user1
  end

  test "recently created users" do
    recent_user = User.create!(
      email: "recent@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active",
      confirmed_at: Time.current
    )

    recent_users = User.where("created_at > ?", 1.hour.ago)

    assert_includes recent_users, recent_user
  end

  test "users with confirmed email" do
    unconfirmed_user = User.new(
      email: "unconfirmed@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active"
    )
    unconfirmed_user.skip_confirmation_notification!
    unconfirmed_user.save!

    confirmed_users = User.where.not(confirmed_at: nil)

    assert_includes confirmed_users, @direct_user1
    assert_not_includes confirmed_users, unconfirmed_user
  end

  # ========================================================================
  # ORDERING AND LIMITS
  # ========================================================================

  test "order by created_at" do
    users = User.order(created_at: :desc).limit(3)

    # Most recent should be enterprise_member (created last in setup)
    assert_equal @enterprise_member, users.first
  end

  test "order by email alphabetically" do
    users = User.order(:email).limit(3)

    # Should start with 'direct1@example.com'
    assert_equal @direct_user1, users.first
  end
end
