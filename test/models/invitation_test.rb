require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  def setup
    # Create a super admin for invitations
    @admin = User.new(
      email: "admin@example.com",
      password: "Password123!",
      user_type: "direct",
      system_role: "super_admin",
      status: "active"
    )
    @admin.skip_confirmation!
    @admin.save!

    # Create team for team invitations
    @team = Team.create!(
      name: "Test Team",
      admin: @admin,
      created_by: @admin
    )

    # Create enterprise group for enterprise invitations
    @enterprise_plan = Plan.create!(
      name: "Enterprise Plan",
      plan_segment: "enterprise",
      amount_cents: 99900,
      active: true
    )

    @enterprise_group = EnterpriseGroup.create!(
      name: "Test Enterprise",
      created_by: @admin,
      plan: @enterprise_plan,
      admin: @admin
    )

    # Basic invitation setup
    @invitation = Invitation.new(
      team: @team,
      email: "newuser@example.com",
      role: "member",
      invited_by: @admin,
      invitation_type: "team"
    )
  end

  # ========================================================================
  # CRITICAL TESTS (Weight: 9-10)
  # ========================================================================

  # Weight: 10 - CR-I1: Email must not exist in users table - prevents duplicates
  test "invitation email cannot exist in users table" do
    # Create existing user
    existing_user = User.create!(
      email: "existing@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    # Try to create invitation with same email
    invitation = Invitation.new(
      team: @team,
      email: "existing@example.com",
      role: "member",
      invited_by: @admin,
      invitation_type: "team"
    )

    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "already has an account"

    # Test case insensitive validation
    invitation.email = "EXISTING@EXAMPLE.COM"
    assert_not invitation.valid?
    assert_includes invitation.errors[:email], "already has an account"
    assert_equal "existing@example.com", invitation.email # Should be normalized
  end

  # Weight: 9 - CR-I4: Accept creates correct user type - user creation integrity
  test "accept! creates correct user type with proper associations" do
    # Test team invitation creates invited user
    team_invitation = Invitation.create!(
      team: @team,
      email: "teamuser@example.com",
      role: "admin",
      invited_by: @admin,
      invitation_type: "team"
    )

    user = team_invitation.accept!(
      password: "Password123!",
      first_name: "Team",
      last_name: "User",
      confirmed_at: Time.current
    )

    assert user.persisted?
    assert_equal "invited", user.user_type
    assert_equal @team, user.team
    assert_equal "admin", user.team_role
    assert_equal "active", user.status
    assert team_invitation.accepted?

    # Test enterprise invitation creates enterprise user
    enterprise_invitation = Invitation.create!(
      invitable: @enterprise_group,
      email: "enterpriseuser@example.com",
      role: "admin",
      invited_by: @admin,
      invitation_type: "enterprise"
    )

    enterprise_user = enterprise_invitation.accept!(
      password: "Password123!",
      first_name: "Enterprise",
      last_name: "User",
      confirmed_at: Time.current
    )

    assert enterprise_user.persisted?
    assert_equal "enterprise", enterprise_user.user_type
    assert_equal @enterprise_group, enterprise_user.enterprise_group
    assert_equal "admin", enterprise_user.enterprise_group_role
    assert_equal "active", enterprise_user.status
    assert enterprise_invitation.accepted?

    # Verify enterprise admin assignment
    @enterprise_group.reload
    assert_equal enterprise_user, @enterprise_group.admin
  end

  # Weight: 9 - CR-I3: Polymorphic type safety - data integrity
  test "polymorphic invitation type safety enforced" do
    # Team invitation requires team_id
    team_invitation = Invitation.new(
      team: nil,
      email: "noteam@example.com",
      role: "member",
      invited_by: @admin,
      invitation_type: "team"
    )

    assert_not team_invitation.valid?
    assert_includes team_invitation.errors[:team_id], "can't be blank"

    # Enterprise invitation requires invitable
    enterprise_invitation = Invitation.new(
      invitable: nil,
      email: "noenterprise@example.com",
      role: "admin",
      invited_by: @admin,
      invitation_type: "enterprise"
    )

    assert_not enterprise_invitation.valid?
    assert_includes enterprise_invitation.errors[:invitable], "can't be blank"

    # Test set_invitable_from_team callback
    legacy_invitation = Invitation.create!(
      team: @team,
      email: "legacy@example.com",
      role: "member",
      invited_by: @admin,
      invitation_type: "team"
    )

    assert_equal @team, legacy_invitation.invitable
    assert_equal "Team", legacy_invitation.invitable_type
  end

  # ========================================================================
  # HIGH PRIORITY TESTS (Weight: 7-8)
  # ========================================================================

  # Weight: 8 - CR-I2: Expiration validation - security best practice
  test "invitation expiration and acceptance rules" do
    invitation = Invitation.create!(
      team: @team,
      email: "expire@example.com",
      role: "member",
      invited_by: @admin,
      invitation_type: "team"
    )

    # Verify expiration is set to 7 days
    assert_not_nil invitation.expires_at
    assert_in_delta 7.days.from_now, invitation.expires_at, 1.minute

    # Cannot accept expired invitation
    invitation.update_column(:expires_at, 1.day.ago)
    assert invitation.expired?

    result = invitation.accept!(password: "Password123!")
    assert_equal false, result

    # Validation prevents acceptance
    invitation.valid?(:accept)
    assert_includes invitation.errors[:base], "Invitation has expired"

    # Test already accepted invitation
    fresh_invitation = Invitation.create!(
      team: @team,
      email: "fresh@example.com",
      role: "member",
      invited_by: @admin,
      invitation_type: "team"
    )

    user = fresh_invitation.accept!(password: "Password123!", confirmed_at: Time.current)
    assert user.persisted?
    assert fresh_invitation.accepted?

    # Cannot accept again
    result = fresh_invitation.accept!(password: "NewPassword123!")
    assert_equal false, result
  end

  # Weight: 8 - IR-I1: Token uniqueness - security requirement
  test "token generation and security" do
    invitations = []

    # Create multiple invitations
    5.times do |i|
      invitations << Invitation.create!(
        team: @team,
        email: "token#{i}@example.com",
        role: "member",
        invited_by: @admin,
        invitation_type: "team"
      )
    end

    # All tokens should be unique
    tokens = invitations.map(&:token)
    assert_equal tokens.uniq.length, tokens.length

    # Tokens should be URL-safe and secure
    tokens.each do |token|
      assert_match /\A[A-Za-z0-9_-]+\z/, token
      assert token.length >= 32 # Secure length
    end

    # Test token uniqueness validation
    duplicate = Invitation.new(
      team: @team,
      email: "duplicate@example.com",
      invited_by: @admin,
      invitation_type: "team"
    )
    duplicate.save!
    duplicate.token = invitations.first.token
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:token], "has already been taken"
  end

  # Weight: 7 - IR-I3: Email normalization - data consistency
  test "email normalization and validation" do
    # Test normalization
    @invitation.email = "  TeSt.UsEr@ExAmPlE.cOm  "
    @invitation.valid?
    assert_equal "test.user@example.com", @invitation.email

    # Test format validation
    valid_emails = [ "user@example.com", "first.last@example.com", "user+tag@example.co.uk" ]
    valid_emails.each do |email|
      @invitation.email = email
      assert @invitation.valid?, "Email '#{email}' should be valid"
    end

    invalid_emails = [ "notanemail", "@example.com", "user@", "" ]
    invalid_emails.each do |email|
      @invitation.email = email
      assert_not @invitation.valid?, "Email '#{email}' should be invalid"
      assert @invitation.errors[:email].any?
    end
  end

  # Weight: 7 - IR-I2: Accepted status immutability - data integrity
  test "invitation status transitions and immutability" do
    @invitation.save!

    # Test status helper methods
    assert @invitation.pending?
    assert_not @invitation.accepted?
    assert_not @invitation.expired?

    # Accept invitation
    user = @invitation.accept!(password: "Password123!", confirmed_at: Time.current)
    assert user.persisted?

    # Status should change
    assert @invitation.accepted?
    assert_not @invitation.pending?

    # Test to_param returns token
    assert_equal @invitation.token, @invitation.to_param
  end

  # ========================================================================
  # MEDIUM PRIORITY TESTS (Weight: 5-6)
  # ========================================================================

  # Weight: 6 - Basic validations (consolidated)
  test "field validations work correctly" do
    # Required fields
    required_fields = {
      email: "can't be blank",
      invited_by: "must exist",
      invitation_type: "can't be blank"
    }

    required_fields.each do |field, error|
      invitation = Invitation.new(@invitation.attributes)
      invitation.send("#{field}=", nil)
      assert_not invitation.valid?
      assert_includes invitation.errors[field], error
    end

    # Token and expires_at are generated, but validate if removed
    @invitation.save!
    @invitation.token = nil
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:token], "can't be blank"

    @invitation.token = "valid_token"
    @invitation.expires_at = nil
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:expires_at], "can't be blank"

    # Role enum validation
    assert_raises(ArgumentError) { @invitation.role = "invalid_role" }
  end

  # Weight: 5 - Query scopes (consolidated)
  test "scopes filter invitations correctly" do
    # Create test invitations
    pending_team = @invitation
    pending_team.save!

    accepted_team = Invitation.create!(
      team: @team,
      email: "accepted@example.com",
      invited_by: @admin,
      invitation_type: "team",
      accepted_at: Time.current
    )

    expired_team = Invitation.create!(
      team: @team,
      email: "expired@example.com",
      invited_by: @admin,
      invitation_type: "team"
    )
    expired_team.update_column(:expires_at, 1.day.ago)

    enterprise_inv = Invitation.create!(
      invitable: @enterprise_group,
      email: "enterprise@example.com",
      invited_by: @admin,
      invitation_type: "enterprise"
    )

    # Test pending scope
    pending = Invitation.pending
    assert_includes pending, pending_team
    assert_not_includes pending, accepted_team

    # Test active scope
    active = Invitation.active
    assert_includes active, pending_team
    assert_not_includes active, expired_team

    # Test type-specific scopes
    assert_includes Invitation.for_teams, pending_team
    assert_not_includes Invitation.for_teams, enterprise_inv

    assert_includes Invitation.for_enterprise, enterprise_inv
    assert_not_includes Invitation.for_enterprise, pending_team
  end

  # Weight: 5 - Helper methods (consolidated)
  test "helper methods work correctly" do
    # Type helpers
    assert @invitation.team_invitation?
    assert_not @invitation.enterprise_invitation?

    enterprise_inv = Invitation.new(invitation_type: "enterprise")
    assert enterprise_inv.enterprise_invitation?
    assert_not enterprise_inv.team_invitation?

    # Default values
    new_invitation = Invitation.new(
      team: @team,
      email: "default@example.com",
      invited_by: @admin,
      invitation_type: "team"
    )
    assert_equal "member", new_invitation.role

    # Callbacks execute correctly
    new_invitation.valid?
    assert_not_nil new_invitation.token
    assert_not_nil new_invitation.expires_at
    assert_equal "default@example.com", new_invitation.email # normalized
  end

  # ========================================================================
  # LOW PRIORITY TESTS (Keep only essential)
  # ========================================================================

  # Weight: 4 - Keep one test for edge cases
  test "handles edge cases correctly" do
    # Multiple invitations to same email for different teams
    @invitation.save!

    other_team = Team.create!(
      name: "Other Team",
      admin: @admin,
      created_by: @admin
    )

    other_invitation = Invitation.new(
      team: other_team,
      email: @invitation.email,
      invited_by: @admin,
      invitation_type: "team"
    )
    assert other_invitation.valid?

    # Track who sent invitation
    assert_equal @admin, @invitation.invited_by
    assert_includes @admin.sent_invitations, @invitation
  end
end
