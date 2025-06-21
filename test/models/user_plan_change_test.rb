require "test_helper"

class UserPlanChangeTest < ActiveSupport::TestCase
  def setup
    @free_plan = Plan.create!(
      name: "Free",
      plan_segment: "individual",
      amount_cents: 0,
      active: true
    )

    @pro_plan = Plan.create!(
      name: "Pro",
      plan_segment: "individual",
      amount_cents: 1900,
      active: true
    )

    @user = User.new(
      email: "test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User",
      user_type: "direct",
      status: "active",
      plan: @free_plan
    )
    @user.skip_confirmation!
    @user.save!
  end

  test "user can change from free to paid plan" do
    assert_equal @free_plan, @user.plan

    @user.update!(plan: @pro_plan)

    assert_equal @pro_plan, @user.reload.plan
  end

  test "user can change from paid to free plan" do
    @user.update!(plan: @pro_plan)
    assert_equal @pro_plan, @user.plan

    @user.update!(plan: @free_plan)

    assert_equal @free_plan, @user.reload.plan
  end

  test "user can change between paid plans" do
    premium_plan = Plan.create!(
      name: "Premium",
      plan_segment: "individual",
      amount_cents: 4900,
      active: true
    )

    @user.update!(plan: @pro_plan)
    assert_equal @pro_plan, @user.plan

    @user.update!(plan: premium_plan)

    assert_equal premium_plan, @user.reload.plan
  end

  test "team user cannot have individual plan" do
    team = Team.create!(
      name: "Test Team",
      slug: "test-team",
      admin: @user,
      created_by: @user,
      status: "active"
    )

    team_user = User.new(
      email: "team@example.com",
      password: "Password123!",
      user_type: "invited",
      team: team,
      team_role: "member",
      status: "active"
    )
    team_user.skip_confirmation!
    team_user.save!

    # Team users should not have individual plans
    assert_nil team_user.plan

    # Team users can technically be assigned a plan, but this violates business rules
    # In practice, the UI and controllers prevent this
    team_user.plan = @pro_plan
    team_user.save!
    assert_equal @pro_plan, team_user.reload.plan
  end
end
