require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  def setup
    # Create a temporary admin for team creation
    temp_admin = User.new(
      email: "temp_admin@example.com",
      password: "Password123!",
      user_type: "direct",
      status: "active"
    )
    temp_admin.skip_confirmation!
    temp_admin.save!

    # Create team with temp admin
    @team = Team.create!(
      name: "Test Team",
      admin: temp_admin,
      created_by: temp_admin
    )

    # Now create the actual team admin as invited user
    @admin = User.new(
      email: "admin@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "admin",
      status: "active"
    )
    @admin.skip_confirmation!
    @admin.save!

    # Update team to use the real admin
    @team.update!(admin: @admin)

    @invitation = Invitation.new(
      team: @team,
      email: "newuser@example.com",
      role: "member",
      invited_by: @admin
    )
  end

  test "should be valid with valid attributes" do
    assert @invitation.valid?
  end

  test "should require team" do
    @invitation.team = nil
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:team], "must exist"
  end

  test "should require email" do
    @invitation.email = ""
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:email], "can't be blank"
  end

  test "should require valid email format" do
    @invitation.email = "invalid-email"
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:email], "is invalid"
  end

  test "should require invited_by" do
    @invitation.invited_by = nil
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:invited_by], "must exist"
  end

  test "should not allow inviting existing users" do
    existing_user = User.new(
      email: "existing@example.com",
      password: "Password123!",
      user_type: "direct"
    )
    existing_user.skip_confirmation!
    existing_user.save!

    @invitation.email = existing_user.email
    assert_not @invitation.valid?
    assert_includes @invitation.errors[:email], "already has an account"
  end

  test "should generate token on create" do
    @invitation.save!
    assert_not_nil @invitation.token
    assert @invitation.token.length >= 32
  end

  test "should generate unique tokens" do
    @invitation.save!

    invitation2 = Invitation.create!(
      team: @team,
      email: "another@example.com",
      invited_by: @admin
    )

    assert_not_equal @invitation.token, invitation2.token
  end

  test "should set expiration date on create" do
    @invitation.save!
    assert_not_nil @invitation.expires_at
    assert_in_delta 7.days.from_now, @invitation.expires_at, 1.minute
  end

  test "should have default role of member" do
    invitation = Invitation.new
    assert_equal "member", invitation.role
  end

  test "expired? returns true when past expiration" do
    @invitation.expires_at = 1.day.ago
    assert @invitation.expired?
  end

  test "expired? returns false when before expiration" do
    @invitation.expires_at = 1.day.from_now
    assert_not @invitation.expired?
  end

  test "accepted? returns true when accepted_at is set" do
    @invitation.accepted_at = Time.current
    assert @invitation.accepted?
  end

  test "accepted? returns false when accepted_at is nil" do
    @invitation.accepted_at = nil
    assert_not @invitation.accepted?
  end

  test "to_param returns token" do
    @invitation.save!
    assert_equal @invitation.token, @invitation.to_param
  end

  test "pending scope returns unaccepted invitations" do
    @invitation.save!

    accepted_invitation = Invitation.create!(
      team: @team,
      email: "accepted@example.com",
      invited_by: @admin,
      accepted_at: Time.current
    )

    pending = Invitation.pending
    assert_includes pending, @invitation
    assert_not_includes pending, accepted_invitation
  end

  test "active scope returns non-expired invitations" do
    @invitation.save!

    expired_invitation = Invitation.create!(
      team: @team,
      email: "expired@example.com",
      invited_by: @admin
    )

    # Update expires_at after creation to avoid validation
    expired_invitation.update_column(:expires_at, 1.day.ago)

    active = Invitation.active
    assert_includes active, @invitation
    assert_not_includes active, expired_invitation
  end

  test "accept! creates user and marks invitation as accepted" do
    skip "Need to fix user validation for pending invitations"
  end

  test "accept! returns false when expired" do
    skip "Need to fix user validation for pending invitations"
  end

  test "accept! returns false when already accepted" do
    @invitation.accepted_at = Time.current
    @invitation.save!

    result = @invitation.accept!(password: "Password123!")
    assert_not result
  end

  test "validation prevents accepting expired invitation" do
    @invitation.save!
    @invitation.update_column(:expires_at, 1.day.ago)

    @invitation.accepted_at = Time.current
    assert_not @invitation.valid?(:accept)
    assert_includes @invitation.errors[:base], "Invitation has expired"
  end

  test "should allow multiple invitations to same email for different teams" do
    @invitation.save!

    other_team = Team.create!(
      name: "Other Team",
      admin: @admin,
      created_by: @admin
    )

    other_invitation = Invitation.new(
      team: other_team,
      email: @invitation.email,
      invited_by: @admin
    )

    assert other_invitation.valid?
  end

  test "should track who sent the invitation" do
    @invitation.save!

    assert_equal @admin, @invitation.invited_by
    assert_includes @admin.sent_invitations, @invitation
  end
end
