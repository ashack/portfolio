require "test_helper"

class UserProfileTest < ActiveSupport::TestCase
  def setup
    @user = users(:direct_user)
    @user.update_columns(
      timezone: "UTC",
      locale: "en",
      profile_visibility: 0
    )
  end

  # Profile field validations
  test "should validate phone number format" do
    valid_numbers = ["+1234567890", "123-456-7890", "(123) 456-7890", "123.456.7890"]
    
    valid_numbers.each do |number|
      @user.phone_number = number
      assert @user.valid?, "#{number} should be valid"
    end
    
    invalid_numbers = ["abc123", "@#$%", "12345678901234567890123"] # Too long
    
    invalid_numbers.each do |number|
      @user.phone_number = number
      assert_not @user.valid?, "#{number} should be invalid"
    end
  end

  test "should validate bio length" do
    @user.bio = "A" * 500
    assert @user.valid?
    
    @user.bio = "A" * 501
    assert_not @user.valid?
    assert_includes @user.errors[:bio], "must be 500 characters or less"
  end

  test "should validate URL formats" do
    valid_urls = ["https://example.com", "http://example.com", "https://sub.example.com/path"]
    
    [:linkedin_url, :twitter_url, :github_url, :website_url].each do |field|
      valid_urls.each do |url|
        @user.send("#{field}=", url)
        assert @user.valid?, "#{url} should be valid for #{field}"
      end
      
      @user.send("#{field}=", "not-a-url")
      assert_not @user.valid?, "Invalid URL should not be valid for #{field}"
    end
  end

  test "should validate timezone" do
    @user.timezone = "America/New_York"
    assert @user.valid?
    
    @user.timezone = "Invalid/Timezone"
    assert_not @user.valid?
  end

  test "should validate locale" do
    @user.locale = "en"
    assert @user.valid?
    
    @user.locale = "invalid"
    assert_not @user.valid?
  end

  # Profile completion calculation
  test "should calculate profile completion percentage" do
    # Start with minimal profile
    @user.update_columns(
      first_name: nil,
      last_name: nil,
      bio: nil,
      phone_number: nil,
      avatar_url: nil,
      linkedin_url: nil,
      timezone: "UTC",
      locale: "en",
      notification_preferences: {},
      two_factor_enabled: false
    )
    
    percentage = @user.calculate_profile_completion
    assert_equal 0, percentage
    
    # Add some fields
    @user.update_columns(
      first_name: "John",
      last_name: "Doe",
      bio: "Test bio"
    )
    
    percentage = @user.calculate_profile_completion
    assert_equal 30, percentage
    
    # Complete profile
    @user.update_columns(
      phone_number: "+1234567890",
      avatar_url: "https://example.com/avatar.jpg",
      linkedin_url: "https://linkedin.com/in/test",
      timezone: "America/New_York",
      locale: "es",
      notification_preferences: { "email_updates" => "1" },
      two_factor_enabled: true
    )
    
    percentage = @user.calculate_profile_completion
    assert_equal 100, percentage
    assert_not_nil @user.profile_completed_at
  end

  test "should track missing profile fields" do
    @user.update_columns(
      first_name: nil,
      bio: nil,
      phone_number: nil
    )
    
    missing = @user.missing_profile_fields
    assert_includes missing, "First name"
    assert_includes missing, "Bio"
    assert_includes missing, "Phone number"
  end

  test "should check if user has social links" do
    @user.update_columns(
      linkedin_url: nil,
      twitter_url: nil,
      github_url: nil,
      website_url: nil
    )
    
    assert_not @user.has_social_links?
    
    @user.update_columns(linkedin_url: "https://linkedin.com/in/test")
    assert @user.has_social_links?
  end

  # Avatar handling
  test "should validate avatar file size" do
    # Attach a large file (simulate)
    @user.avatar.attach(
      io: StringIO.new("x" * 6.megabytes),
      filename: "large.jpg",
      content_type: "image/jpeg"
    )
    
    assert_not @user.valid?
    assert_includes @user.errors[:avatar], "is too large (maximum is 5MB)"
  end

  test "should validate avatar content type" do
    # Valid types
    valid_types = ["image/jpeg", "image/png", "image/gif", "image/webp"]
    
    valid_types.each do |type|
      @user.avatar.attach(
        io: StringIO.new("test"),
        filename: "test.jpg",
        content_type: type
      )
      assert @user.valid?, "#{type} should be valid"
    end
    
    # Invalid type
    @user.avatar.attach(
      io: StringIO.new("test"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )
    
    assert_not @user.valid?
    assert_includes @user.errors[:avatar], "must be a JPEG, PNG, GIF, or WebP image"
  end

  test "should return display avatar URL" do
    # No avatar
    assert_nil @user.display_avatar_url
    
    # Avatar URL
    @user.update(avatar_url: "https://example.com/avatar.jpg")
    assert_equal "https://example.com/avatar.jpg", @user.display_avatar_url
    
    # Attached avatar takes precedence
    @user.avatar.attach(
      io: StringIO.new("test"),
      filename: "avatar.jpg",
      content_type: "image/jpeg"
    )
    assert_match /rails\/active_storage/, @user.display_avatar_url
  end

  # Timezone handling
  test "should return timezone as ActiveSupport::TimeZone" do
    @user.update(timezone: "America/New_York")
    assert_instance_of ActiveSupport::TimeZone, @user.time_zone
    assert_equal "America/New_York", @user.time_zone.name
  end

  # Profile visibility
  test "should have profile visibility enum" do
    assert @user.respond_to?(:public_profile?)
    assert @user.respond_to?(:team_only?)
    assert @user.respond_to?(:private_profile?)
    
    @user.public_profile!
    assert @user.public_profile?
    
    @user.team_only!
    assert @user.team_only?
    
    @user.private_profile!
    assert @user.private_profile?
  end

  # Notification preferences
  test "should store notification preferences as JSON" do
    prefs = {
      "email_marketing" => "1",
      "email_security" => "1",
      "frequency" => "daily"
    }
    
    @user.update(notification_preferences: prefs)
    @user.reload
    
    assert_equal "1", @user.notification_preferences["email_marketing"]
    assert_equal "daily", @user.notification_preferences["frequency"]
  end
end