require "test_helper"

class PaySimpleTest < ActiveSupport::TestCase
  # Don't use fixtures for this test
  self.use_instantiated_fixtures = false

  test "Pay gem is loaded and configured" do
    # Check that Pay module is available
    assert defined?(Pay), "Pay module should be defined"

    # Check that Pay models are available
    assert defined?(Pay::Customer), "Pay::Customer should be defined"
    assert defined?(Pay::Subscription), "Pay::Subscription should be defined"
    assert defined?(Pay::PaymentMethod), "Pay::PaymentMethod should be defined"
  end

  test "Pay configuration is set in test environment" do
    # Check that Pay is configured
    assert_equal "Test SaaS App", Pay.business_name
    assert_equal "test@example.com", Pay.support_email.to_s
    assert_equal false, Pay.automount_routes
  end

  test "models include Pay::Billable functionality" do
    # Create a simple user without fixtures
    user = User.new(
      email: "paytest@example.com",
      password: "Password123!",
      first_name: "Pay",
      last_name: "Test",
      user_type: "direct",
      status: "active"
    )

    # Check Pay methods are available
    assert user.respond_to?(:payment_processor), "User should respond to payment_processor"
    assert user.respond_to?(:set_payment_processor), "User should respond to set_payment_processor"
    # pay_customer is created dynamically, not a method on the model
    assert user.respond_to?(:pay_customers), "User should respond to pay_customers"
  end

  test "teams include Pay::Billable functionality" do
    # Check that Team model has Pay methods
    team = Team.new(name: "Test Team")

    assert team.respond_to?(:payment_processor), "Team should respond to payment_processor"
    assert team.respond_to?(:set_payment_processor), "Team should respond to set_payment_processor"
    assert team.respond_to?(:pay_customers), "Team should respond to pay_customers"
  end

  test "enterprise groups include Pay::Billable functionality" do
    # Check that EnterpriseGroup model has Pay methods
    enterprise = EnterpriseGroup.new(name: "Test Enterprise")

    assert enterprise.respond_to?(:payment_processor), "EnterpriseGroup should respond to payment_processor"
    assert enterprise.respond_to?(:set_payment_processor), "EnterpriseGroup should respond to set_payment_processor"
    assert enterprise.respond_to?(:pay_customers), "EnterpriseGroup should respond to pay_customers"
  end
end
