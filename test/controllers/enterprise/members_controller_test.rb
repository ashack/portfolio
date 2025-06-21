require "test_helper"

class Enterprise::MembersControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create super admin for enterprise group creation
    super_admin = User.create!(
      email: "super@example.com",
      password: "Password123!",
      system_role: "super_admin",
      user_type: "direct",
      status: "active"
    )

    # Create enterprise plan
    plan = Plan.create!(
      name: "Enterprise Plan",
      plan_segment: "enterprise",
      amount_cents: 99900,
      interval: "month"
    )

    # Create enterprise group
    @enterprise_group = EnterpriseGroup.create!(
      name: "Test Enterprise",
      slug: "test-enterprise",
      created_by: super_admin,
      plan: plan,
      max_members: 50,
      status: "active"
    )

    # Create and sign in enterprise admin
    @enterprise_admin = sign_in_with(
      email: "admin@enterprise.com",
      user_type: "enterprise",
      enterprise_group_role: "admin",
      enterprise_group: @enterprise_group
    )
  end

  test "should get members index" do
    get members_path(enterprise_group_slug: @enterprise_group.slug)
    assert_response :success
  end

  test "should get new invitation form" do
    get new_member_path(enterprise_group_slug: @enterprise_group.slug)
    assert_response :success
  end

  test "should create invitation" do
    assert_difference("Invitation.count") do
      post members_path(enterprise_group_slug: @enterprise_group.slug), params: {
        invitation: {
          email: "newmember@example.com",
          role: "member"
        }
      }
    end
    assert_redirected_to members_path(enterprise_group_slug: @enterprise_group.slug)
  end

  test "non-admin cannot invite members" do
    member = sign_in_with(
      email: "member@enterprise.com",
      user_type: "enterprise",
      enterprise_group_role: "member",
      enterprise_group: @enterprise_group
    )

    get new_member_path(enterprise_group_slug: @enterprise_group.slug)
    assert_redirected_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug)
  end
end
