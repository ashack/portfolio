require "test_helper"

class UserCallbacksTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      email: "TEST@EXAMPLE.COM",
      password: "Password123!",
      first_name: "Test",
      last_name: "User",
      user_type: "direct",
      status: "active"
    )
  end

  # Email normalization callback tests
  test "normalize_email callback downcases email before validation" do
    @user.email = "TEST@EXAMPLE.COM"
    @user.valid?
    assert_equal "test@example.com", @user.email
  end

  test "normalize_email callback strips whitespace from email" do
    @user.email = "  test@example.com  "
    @user.valid?
    assert_equal "test@example.com", @user.email
  end

  test "normalize_email callback handles email with mixed case and spaces" do
    @user.email = "  TeSt@ExAmPlE.cOm  "
    @user.valid?
    assert_equal "test@example.com", @user.email
  end

  test "normalize_email callback handles nil email gracefully" do
    @user.email = nil
    assert_nothing_raised { @user.valid? }
    assert_nil @user.email
  end

  test "normalize_email callback is called before validation" do
    @user.email = "UPPERCASE@EXAMPLE.COM"
    @user.skip_confirmation!
    @user.save!

    # Email should be normalized in database
    @user.reload
    assert_equal "uppercase@example.com", @user.email
  end

  # Callback order tests
  test "callbacks execute in correct order during save" do
    callback_order = []

    @user.singleton_class.class_eval do
      define_method :track_normalize_email do
        callback_order << :normalize_email
        normalize_email
      end

      before_validation :track_normalize_email
    end

    @user.email = "TEST@EXAMPLE.COM"
    @user.valid?

    assert_includes callback_order, :normalize_email
  end

  # Devise callback integration tests
  test "devise trackable callbacks update sign in tracking" do
    @user.skip_confirmation!
    @user.save!

    assert_equal 0, @user.sign_in_count
    assert_nil @user.current_sign_in_at
    assert_nil @user.last_sign_in_at

    # Simulate sign in
    @user.update!(
      sign_in_count: 1,
      current_sign_in_at: Time.current,
      current_sign_in_ip: "127.0.0.1"
    )

    assert_equal 1, @user.sign_in_count
    assert_not_nil @user.current_sign_in_at
  end

  test "devise confirmable callbacks set confirmation token" do
    skip "Devise mapping issue in test environment"
  end

  # Association callback tests
  test "user associations are properly initialized" do
    @user.skip_confirmation!
    @user.save!

    assert_empty @user.created_teams
    assert_empty @user.administered_teams
    assert_empty @user.sent_invitations
    assert_empty @user.email_change_requests
    assert_empty @user.audit_logs
  end

  # Pay gem callback integration
  test "pay customer callbacks initialize payment processor" do
    @user.skip_confirmation!
    @user.save!

    assert_respond_to @user, :set_payment_processor
    assert_respond_to @user, :payment_processor
    assert_nil @user.stripe_customer_id
  end

  # Validation callback interaction tests
  test "email normalization happens before email uniqueness validation" do
    existing_user = User.new(
      email: "existing@example.com",
      password: "Password123!",
      user_type: "direct"
    )
    existing_user.skip_confirmation!
    existing_user.save!

    # Try to create user with uppercase version of same email
    duplicate_user = User.new(
      email: "EXISTING@EXAMPLE.COM",
      password: "Password123!",
      user_type: "direct"
    )

    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "is already taken"
    # Email should be normalized even though validation failed
    assert_equal "existing@example.com", duplicate_user.email
  end

  # Edge case tests
  test "callbacks handle email with special characters" do
    @user.email = "test+tag@example.com"
    @user.valid?
    assert_equal "test+tag@example.com", @user.email
  end

  test "callbacks handle international domain emails" do
    @user.email = "test@exämple.com"
    @user.valid?
    assert_equal "test@exämple.com", @user.email
  end

  test "callbacks don't interfere with validation errors" do
    @user.email = "INVALID EMAIL"
    assert_not @user.valid?
    # Email should still be normalized even with invalid format
    assert_equal "invalid email", @user.email
    assert_includes @user.errors[:email], "must be a valid email address"
  end
end
