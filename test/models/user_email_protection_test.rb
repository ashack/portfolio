require "test_helper"

class UserEmailProtectionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User",
      user_type: "direct",
      confirmed_at: Time.current
    )
  end
  
  test "prevents direct email changes" do
    original_email = @user.email
    
    @user.email = "newemail@example.com"
    assert_not @user.save
    assert @user.errors[:email].include?("cannot be changed directly. Please use the email change request system.")
    
    @user.reload
    assert_equal original_email, @user.email
  end
  
  test "allows email change with authorization flag" do
    Thread.current[:email_change_authorized] = true
    
    @user.email = "authorized@example.com"
    assert @user.save
    assert_equal "authorized@example.com", @user.email
  ensure
    Thread.current[:email_change_authorized] = false
  end
  
  test "allows super admin to change emails" do
    super_admin = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      system_role: "super_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )
    
    Thread.current[:current_admin] = super_admin
    
    @user.email = "changed@example.com"
    assert @user.save
    assert_equal "changed@example.com", @user.email
  ensure
    Thread.current[:current_admin] = nil
  end
  
  test "allows email setting during user creation" do
    new_user = User.new(
      email: "newuser@example.com",
      password: "Password123!",
      user_type: "direct"
    )
    
    assert new_user.save
    assert_equal "newuser@example.com", new_user.email
  end
  
  test "email protection triggers validation error not exception" do
    @user.email = "blocked@example.com"
    
    assert_nothing_raised do
      @user.save
    end
    
    assert_not @user.valid?
    assert @user.errors[:email].present?
  end
  
  test "email change attempt is logged" do
    logs = []
    Rails.logger.stub :warn, ->(msg) { logs << msg } do
      @user.email = "hacker@example.com"
      @user.save
    end
    
    assert logs.any? { |log| log.include?("[SECURITY] Unauthorized email change attempt") }
    assert logs.any? { |log| log.include?("from test@example.com to hacker@example.com") }
  end
  
  test "email is reverted on unauthorized change attempt" do
    original_email = @user.email
    
    @user.email = "attacker@example.com"
    @user.first_name = "Updated"
    
    @user.save
    
    # Email should be reverted but other changes blocked too due to validation failure
    assert_equal original_email, @user.email
    assert_not_equal "Updated", @user.first_name
  end
  
  test "authorized email change through EmailChangeRequest works" do
    # Simulate the EmailChangeRequest approval process
    email_change_request = EmailChangeRequest.create!(
      user: @user,
      new_email: "approved@example.com",
      reason: "Changing to new work email",
      token: SecureRandom.urlsafe_base64(32),
      requested_at: Time.current,
      expires_at: 30.days.from_now
    )
    
    # Simulate admin approval
    admin = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      system_role: "super_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )
    
    assert email_change_request.approve!(admin)
    
    @user.reload
    assert_equal "approved@example.com", @user.email
  end
end