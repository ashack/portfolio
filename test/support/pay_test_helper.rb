# Pay Test Helper
# Provides helper methods and mocks for testing Pay gem functionality
# without hitting real payment processor APIs

module PayTestHelper
  extend ActiveSupport::Concern

  included do
    # Set up Pay gem configuration for tests
    setup do
      setup_pay_test_configuration
    end
  end

  # Configure Pay gem for test environment
  def setup_pay_test_configuration
    # Configure Pay to use test mode
    Pay.setup do |config|
      config.business_name = "Test SaaS App"
      config.business_address = "123 Test St, Test City, TS 12345"
      config.application_name = "Test SaaS App"
      config.support_email = "test@example.com"
      config.default_product_name = "Test Product"
      config.default_plan_name = "test_plan"
      config.automount_routes = false # Disable routes in tests
    end
  end

  # Create a Pay customer for a model (User, Team, or EnterpriseGroup)
  def create_pay_customer_for(model, attributes = {})
    default_attributes = {
      processor: "stripe",
      processor_id: "cus_test_#{model.class.name.downcase}_#{model.id}",
      default: true,
      data: {
        email: model.respond_to?(:email) ? model.email : "#{model.class.name.downcase}@example.com",
        name: model.respond_to?(:name) ? model.name : model.class.name
      }
    }

    pay_customer = model.payment_processor || model.set_payment_processor(:stripe)
    pay_customer.update!(default_attributes.merge(attributes))
    pay_customer
  end

  # Create a subscription for a Pay customer
  def create_subscription_for(pay_customer, attributes = {})
    default_attributes = {
      name: "Test Subscription",
      processor: "stripe",
      processor_id: "sub_test_#{SecureRandom.hex(8)}",
      processor_plan: "price_test_plan",
      quantity: 1,
      status: "active",
      trial_ends_at: nil,
      ends_at: nil
    }

    pay_customer.subscriptions.create!(default_attributes.merge(attributes))
  end

  # Create a payment method for a Pay customer
  def create_payment_method_for(pay_customer, attributes = {})
    default_attributes = {
      processor: "stripe",
      processor_id: "pm_test_#{SecureRandom.hex(8)}",
      type: "card",
      default: true,
      data: {
        brand: "visa",
        last4: "4242",
        exp_month: 12,
        exp_year: 2.years.from_now.year
      }
    }

    pay_customer.payment_methods.create!(default_attributes.merge(attributes))
  end

  # Stub common Pay gem methods for models
  def stub_pay_customer_methods(model)
    # Stub customer name and email methods
    model.define_singleton_method(:customer_name) do
      if respond_to?(:name)
        name
      elsif respond_to?(:full_name)
        full_name
      else
        "Test Customer"
      end
    end

    model.define_singleton_method(:customer_email) do
      if respond_to?(:email)
        email
      elsif self.is_a?(Team)
        "team-#{id}@example.com"
      elsif self.is_a?(EnterpriseGroup)
        "enterprise-#{id}@example.com"
      else
        "customer-#{id}@example.com"
      end
    end
  end

  # Helper to quickly set up a model with an active subscription
  def setup_active_subscription(model, plan_name = "test_plan")
    pay_customer = create_pay_customer_for(model)
    create_payment_method_for(pay_customer)
    create_subscription_for(pay_customer, {
      processor_plan: "price_#{plan_name}",
      status: "active"
    })
  end

  # Helper to set up a model with a trial subscription
  def setup_trial_subscription(model, plan_name = "test_plan", trial_days = 14)
    pay_customer = create_pay_customer_for(model)
    create_subscription_for(pay_customer, {
      processor_plan: "price_#{plan_name}",
      status: "trialing",
      trial_ends_at: trial_days.days.from_now
    })
  end

  # Helper to set up a cancelled subscription
  def setup_cancelled_subscription(model, plan_name = "test_plan")
    pay_customer = create_pay_customer_for(model)
    create_payment_method_for(pay_customer)
    create_subscription_for(pay_customer, {
      processor_plan: "price_#{plan_name}",
      status: "canceled",
      ends_at: 7.days.from_now
    })
  end

  # Mock Stripe API responses for tests
  def mock_stripe_customer_create
    {
      id: "cus_test_#{SecureRandom.hex(8)}",
      object: "customer",
      email: "test@example.com",
      created: Time.current.to_i,
      livemode: false
    }
  end

  def mock_stripe_subscription_create
    {
      id: "sub_test_#{SecureRandom.hex(8)}",
      object: "subscription",
      customer: "cus_test_12345",
      status: "active",
      created: Time.current.to_i,
      current_period_start: Time.current.to_i,
      current_period_end: 1.month.from_now.to_i,
      items: {
        data: [ {
          id: "si_test_12345",
          price: {
            id: "price_test_plan",
            product: "prod_test_12345"
          }
        } ]
      }
    }
  end

  # Assertion helpers for Pay functionality
  def assert_has_active_subscription(model)
    assert model.subscribed?, "#{model.class.name} should have an active subscription"
  end

  def assert_no_active_subscription(model)
    assert_not model.subscribed?, "#{model.class.name} should not have an active subscription"
  end

  def assert_subscription_status(model, expected_status)
    subscription = model.subscription
    assert_not_nil subscription, "#{model.class.name} should have a subscription"
    assert_equal expected_status, subscription.status,
      "Expected subscription status to be #{expected_status}, but was #{subscription.status}"
  end

  def assert_trial_active(model)
    subscription = model.subscription
    assert_not_nil subscription, "#{model.class.name} should have a subscription"
    assert_equal "trialing", subscription.status
    assert subscription.trial_ends_at > Time.current, "Trial should not have ended"
  end
end
