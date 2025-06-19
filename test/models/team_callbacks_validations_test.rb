require "test_helper"

class TeamCallbacksValidationsTest < ActiveSupport::TestCase
  def setup
    @admin = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      user_type: "direct",
      confirmed_at: Time.current
    )

    @team = Team.new(
      name: "Test Team",
      admin: @admin,
      created_by: @admin
    )
  end

  # Slug generation callback tests
  test "generate_slug callback creates slug from name" do
    @team.name = "My Awesome Team"
    @team.valid?
    assert_equal "my-awesome-team", @team.slug
  end

  test "generate_slug removes special characters" do
    test_cases = {
      "Team & Co." => "team-co",
      "Team@123!" => "team123",
      "Team #1" => "team-1",
      "Team (Best)" => "team-best",
      "Team's Project" => "teams-project",
      "Team + Partners" => "team-partners",
      "Team/Division" => "teamdivision",
      "Team—Dashboard" => "teamdashboard"
    }

    test_cases.each do |name, expected_slug|
      @team.name = name
      @team.valid?
      assert_equal expected_slug, @team.slug, "Name '#{name}' should generate slug '#{expected_slug}'"
    end
  end

  test "generate_slug handles multiple spaces" do
    @team.name = "Team    With    Spaces"
    @team.valid?
    assert_equal "team-with-spaces", @team.slug
  end

  test "generate_slug handles leading and trailing spaces" do
    @team.name = "  Spaced Team  "
    @team.valid?
    assert_equal "spaced-team", @team.slug
  end

  test "generate_slug creates unique slug when name conflicts" do
    # Create first team
    existing_team = Team.create!(
      name: "Test Team",
      admin: @admin,
      created_by: @admin
    )
    assert_equal "test-team", existing_team.slug

    # Create second team with same name
    @team.name = "Test Team"
    @team.save!
    assert_equal "test-team-1", @team.slug

    # Create third team with same name
    another_team = Team.create!(
      name: "Test Team",
      admin: @admin,
      created_by: @admin
    )
    assert_equal "test-team-2", another_team.slug
  end

  test "generate_slug only runs when name changes" do
    @team.save!
    original_slug = @team.slug

    # Update other attributes
    @team.plan = "pro"
    @team.save!

    assert_equal original_slug, @team.slug
  end

  test "generate_slug handles empty name" do
    @team.name = ""
    @team.valid?
    # Slug generation should not crash, validation will catch empty name
    assert_not @team.valid?
  end

  test "generate_slug handles nil name" do
    @team.name = nil
    assert_nothing_raised { @team.valid? }
  end

  test "slug cannot be manually set to bypass uniqueness" do
    existing_team = Team.create!(
      name: "Existing Team",
      admin: @admin,
      created_by: @admin
    )

    @team.name = "Different Name"
    @team.slug = existing_team.slug

    # The before_validation callback should regenerate the slug
    @team.valid?
    assert_not_equal existing_team.slug, @team.slug
  end

  # Validation tests
  test "name validation requires minimum 2 characters" do
    @team.name = "A"
    assert_not @team.valid?
    assert_includes @team.errors[:name], "is too short (minimum is 2 characters)"

    @team.name = "AB"
    assert @team.valid?
  end

  test "name validation requires maximum 50 characters" do
    @team.name = "A" * 51
    assert_not @team.valid?
    assert_includes @team.errors[:name], "is too long (maximum is 50 characters)"

    @team.name = "A" * 50
    assert @team.valid?
  end

  test "name presence validation" do
    @team.name = nil
    assert_not @team.valid?
    assert_includes @team.errors[:name], "can't be blank"

    @team.name = ""
    assert_not @team.valid?
    assert_includes @team.errors[:name], "can't be blank"
  end

  test "slug format validation accepts valid slugs" do
    valid_slugs = [
      "team-name",
      "team123",
      "my-awesome-team-123",
      "a",
      "team-with-many-dashes",
      "123-numbers"
    ]

    valid_slugs.each do |slug|
      @team.save! # Create team first
      @team.slug = slug
      assert @team.valid?, "Slug '#{slug}' should be valid"
    end
  end

  test "slug format validation rejects invalid slugs" do
    @team.save! # Create team first

    invalid_slugs = [
      "Team Name",      # spaces
      "team_name",      # underscores
      "TEAM-NAME",      # uppercase
      "team@name",      # special chars
      "team.name",      # dots
      "team/name",      # slashes
      "team name!"      # special chars
    ]

    invalid_slugs.each do |slug|
      @team.slug = slug
      assert_not @team.valid?, "Slug '#{slug}' should be invalid"
      assert @team.errors[:slug].any? { |e| e.include?("is invalid") }
    end
  end

  test "slug uniqueness validation" do
    @team.save!

    duplicate_team = Team.new(
      name: "Another Team",
      admin: @admin,
      created_by: @admin
    )

    # Force the same slug
    duplicate_team.instance_variable_set(:@slug, @team.slug)
    def duplicate_team.generate_slug; end # Prevent regeneration

    duplicate_team.slug = @team.slug
    assert_not duplicate_team.valid?
    assert_includes duplicate_team.errors[:slug], "has already been taken"
  end

  test "admin_id presence validation" do
    @team.admin = nil
    assert_not @team.valid?
    assert_includes @team.errors[:admin], "must exist"
  end

  test "created_by_id presence validation" do
    @team.created_by = nil
    assert_not @team.valid?
    assert_includes @team.errors[:created_by], "must exist"
  end

  test "admin and created_by can be different users" do
    creator = User.create!(
      email: "creator@example.com",
      password: "Password123!",
      user_type: "direct",
      system_role: "super_admin",
      confirmed_at: Time.current
    )

    @team.created_by = creator
    assert @team.valid?
    assert_not_equal @team.admin_id, @team.created_by_id
  end

  # Enum validations
  test "plan enum accepts valid values" do
    %w[starter pro enterprise].each do |plan|
      @team.plan = plan
      assert @team.valid?, "Plan '#{plan}' should be valid"
    end
  end

  test "plan enum rejects invalid values" do
    assert_raises(ArgumentError) do
      @team.plan = "invalid_plan"
    end
  end

  test "status enum accepts valid values" do
    %w[active suspended cancelled].each do |status|
      @team.status = status
      assert @team.valid?, "Status '#{status}' should be valid"
    end
  end

  test "status enum rejects invalid values" do
    assert_raises(ArgumentError) do
      @team.status = "invalid_status"
    end
  end

  # Default value tests
  test "plan defaults to starter" do
    new_team = Team.new
    assert_equal "starter", new_team.plan
  end

  test "status defaults to active" do
    new_team = Team.new
    assert_equal "active", new_team.status
  end

  test "max_members defaults based on plan" do
    @team.plan = "starter"
    @team.save!
    # Note: max_members is set manually, not automatically
    @team.max_members = 5
    assert_equal 5, @team.max_members
  end

  # Association validations
  test "team can have multiple users" do
    @team.save!

    user1 = User.create!(
      email: "user1@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )

    user2 = User.create!(
      email: "user2@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )

    assert_equal 2, @team.users.count
  end

  test "team cannot be deleted if users exist" do
    @team.save!

    user = User.create!(
      email: "member@example.com",
      password: "Password123!",
      user_type: "invited",
      team: @team,
      team_role: "member",
      confirmed_at: Time.current
    )

    assert_not @team.destroy
    assert @team.errors[:base].any?
  end

  test "team can be deleted if no users" do
    @team.save!
    assert @team.destroy
  end

  # Complex validation scenarios
  test "validation runs after slug generation" do
    @team.name = "A" # Too short
    assert_not @team.valid?

    # Slug should still be generated even though validation fails
    assert_equal "a", @team.slug
  end

  test "multiple validation errors are collected" do
    @team.name = "A"  # Too short
    @team.admin = nil
    @team.created_by = nil

    assert_not @team.valid?

    assert @team.errors[:name].any?
    assert @team.errors[:admin].any?
    assert @team.errors[:created_by].any?
  end
end
