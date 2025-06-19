require "test_helper"

class EmailChangeRequestCallbacksValidationsTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "user@example.com",
      password: "Password123!",
      confirmed_at: Time.current
    )

    @request = EmailChangeRequest.new(
      user: @user,
      new_email: "newemail@example.com",
      reason: "I want to change my email for personal reasons"
    )
  end

  # Token generation callback tests
  test "generate_token callback creates token before validation" do
    assert_nil @request.token
    @request.valid?
    assert_not_nil @request.token
    assert @request.token.length >= 32
  end

  test "generate_token creates unique tokens" do
    @request.save!
    token1 = @request.token

    request2 = EmailChangeRequest.create!(
      user: User.create!(
        email: "other@example.com",
        password: "Password123!",
        confirmed_at: Time.current
      ),
      new_email: "other_new@example.com",
      reason: "Another reason for changing email"
    )

    assert_not_equal token1, request2.token
  end

  test "generate_token only runs for new records" do
    @request.save!
    original_token = @request.token

    @request.reason = "Updated reason"
    @request.save!

    assert_equal original_token, @request.token
  end

  # Timestamp callback tests
  test "set_requested_at callback sets timestamp before validation" do
    assert_nil @request.requested_at
    @request.valid?
    assert_not_nil @request.requested_at
    assert_in_delta Time.current, @request.requested_at, 1.second
  end

  test "set_requested_at only runs for new records" do
    @request.save!
    original_time = @request.requested_at

    sleep 0.1 # Ensure time difference
    @request.reason = "Updated reason"
    @request.save!

    assert_equal original_time.to_i, @request.requested_at.to_i
  end

  # Email validation tests
  test "new_email presence validation" do
    @request.new_email = nil
    assert_not @request.valid?
    assert_includes @request.errors[:new_email], "can't be blank"

    @request.new_email = ""
    assert_not @request.valid?
    assert_includes @request.errors[:new_email], "can't be blank"
  end

  test "new_email format validation accepts valid emails" do
    valid_emails = [
      "user@example.com",
      "user.name@example.com",
      "user+tag@example.co.uk",
      "user_name@sub.example.com"
    ]

    valid_emails.each do |email|
      @request.new_email = email
      @request.valid?
      assert_not @request.errors[:new_email].any? { |e| e.include?("is invalid") },
        "Email '#{email}' should not have format error"
    end
  end

  test "new_email format validation rejects invalid emails" do
    invalid_emails = [
      "plaintext",
      "@example.com",
      "user@",
      "user name@example.com"
    ]

    invalid_emails.each do |email|
      @request.new_email = email
      @request.valid?
      assert @request.errors[:new_email].any? { |e| e.include?("is invalid") },
        "Email '#{email}' should have format error"
    end
  end

  test "new_email must be different from current email" do
    @request.new_email = @user.email
    assert_not @request.valid?
    assert_includes @request.errors[:new_email], "must be different from current email"
  end

  test "new_email comparison is case sensitive" do
    # The model does case-sensitive comparison
    @request.new_email = @user.email.upcase
    assert @request.valid?
  end

  test "new_email cannot be taken by another user" do
    other_user = User.create!(
      email: "taken@example.com",
      password: "Password123!",
      confirmed_at: Time.current
    )

    @request.new_email = "taken@example.com"
    assert_not @request.valid?
    assert_includes @request.errors[:new_email], "is already taken by another user"
  end

  test "new_email validation is case sensitive for existing users" do
    other_user = User.create!(
      email: "taken@example.com",
      password: "Password123!",
      confirmed_at: Time.current
    )

    # Model does case-sensitive check for existing users
    @request.new_email = "TAKEN@EXAMPLE.COM"
    assert @request.valid?
  end

  # Reason validation tests
  test "reason presence validation" do
    @request.reason = nil
    assert_not @request.valid?
    assert_includes @request.errors[:reason], "can't be blank"

    @request.reason = ""
    assert_not @request.valid?
    assert_includes @request.errors[:reason], "can't be blank"
  end

  test "reason minimum length validation" do
    @request.reason = "Too short"
    assert_not @request.valid?
    assert_includes @request.errors[:reason], "is too short (minimum is 10 characters)"

    @request.reason = "Just right"  # 10 characters
    assert @request.valid?
  end

  test "reason maximum length validation" do
    @request.reason = "A" * 501
    assert_not @request.valid?
    assert_includes @request.errors[:reason], "is too long (maximum is 500 characters)"

    @request.reason = "A" * 500
    assert @request.valid?
  end

  # Token validation tests
  test "token presence validation" do
    @request.save!
    @request.token = nil
    assert_not @request.valid?
    assert_includes @request.errors[:token], "can't be blank"
  end

  test "token uniqueness validation" do
    @request.save!

    duplicate_request = EmailChangeRequest.new(
      user: User.create!(
        email: "another@example.com",
        password: "Password123!",
        confirmed_at: Time.current
      ),
      new_email: "another_new@example.com",
      reason: "Another reason for change"
    )

    # Override the before_validation callback to force the same token
    duplicate_request.instance_eval do
      def generate_token
        self.token = EmailChangeRequest.first.token
      end
    end

    assert_not duplicate_request.valid?
    assert_includes duplicate_request.errors[:token], "has already been taken"
  end

  # Requested at validation
  test "requested_at presence validation" do
    @request.save!
    @request.requested_at = nil
    assert_not @request.valid?
    assert_includes @request.errors[:requested_at], "can't be blank"
  end

  # Pending request validation
  test "user cannot have multiple pending requests" do
    @request.save!

    duplicate_request = EmailChangeRequest.new(
      user: @user,
      new_email: "another@example.com",
      reason: "Another reason for changing email"
    )

    assert_not duplicate_request.valid?
    assert_includes duplicate_request.errors[:base], "You already have a pending email change request"
  end

  test "user can have new request after previous is approved" do
    @request.save!

    # Create a valid approver user
    approver = User.create!(
      email: "approver@example.com",
      password: "Password123!",
      system_role: "super_admin",
      confirmed_at: Time.current
    )

    @request.update!(status: "approved", approved_by_id: approver.id, approved_at: Time.current)

    new_request = EmailChangeRequest.new(
      user: @user,
      new_email: "another@example.com",
      reason: "Another reason for changing email"
    )

    assert new_request.valid?
  end

  test "user can have new request after previous is rejected" do
    @request.save!

    # Create a valid approver user
    approver = User.create!(
      email: "approver2@example.com",
      password: "Password123!",
      system_role: "super_admin",
      confirmed_at: Time.current
    )

    @request.update!(status: "rejected", approved_by_id: approver.id, approved_at: Time.current)

    new_request = EmailChangeRequest.new(
      user: @user,
      new_email: "another@example.com",
      reason: "Another reason for changing email"
    )

    assert new_request.valid?
  end

  test "user can have new request after previous expires" do
    @request.save!
    @request.update!(status: "expired")

    new_request = EmailChangeRequest.new(
      user: @user,
      new_email: "another@example.com",
      reason: "Another reason for changing email"
    )

    assert new_request.valid?
  end

  # Status enum validation
  test "status enum accepts valid values" do
    %w[pending approved rejected expired].each do |status|
      @request.status = status
      assert @request.valid?, "Status '#{status}' should be valid"
    end
  end

  test "status enum rejects invalid values" do
    assert_raises(ArgumentError) do
      @request.status = "invalid_status"
    end
  end

  test "status defaults to pending" do
    new_request = EmailChangeRequest.new
    assert_equal "pending", new_request.status
  end

  # After create callback
  test "send_request_notification is called after create" do
    # Mock the mailer
    mock_mailer = Minitest::Mock.new
    mock_mailer.expect :deliver_later, true

    EmailChangeMailer.stub :request_submitted, ->(request) { mock_mailer } do
      @request.save!
    end

    assert_mock mock_mailer
  end

  # Complex validation scenarios
  test "callbacks run in correct order" do
    callback_order = []

    @request.singleton_class.class_eval do
      define_method :track_generate_token do
        callback_order << :generate_token
        generate_token
      end

      define_method :track_set_requested_at do
        callback_order << :set_requested_at
        set_requested_at
      end

      before_validation :track_generate_token, if: :new_record?
      before_validation :track_set_requested_at, if: :new_record?
    end

    @request.valid?

    assert_equal [ :generate_token, :set_requested_at ], callback_order
  end

  test "validation errors don't prevent callbacks" do
    @request.new_email = "invalid"
    @request.reason = "short"

    assert_not @request.valid?

    # Callbacks should still have run
    assert_not_nil @request.token
    assert_not_nil @request.requested_at
  end

  test "all validations run even with multiple errors" do
    @request.new_email = @user.email  # Same as current
    @request.reason = "short"          # Too short

    assert_not @request.valid?

    assert @request.errors[:new_email].any?, "Should have new_email error"
    assert @request.errors[:reason].any?, "Should have reason error"

    # Test token validation separately since it's generated before validation
    saved_request = EmailChangeRequest.create!(
      user: @user,
      new_email: "valid@example.com",
      reason: "Valid reason for change"
    )

    saved_request.token = nil
    assert_not saved_request.valid?
    assert saved_request.errors[:token].any?, "Should have token error when nil"
  end
end
