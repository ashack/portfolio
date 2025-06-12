Pay.setup do |config|
  config.business_name = "SaaS App"
  config.business_address = "123 Business St, City, State 12345"
  config.application_name = "SaaS App"
  config.support_email = "support@saasapp.com"

  config.default_product_name = "SaaS App"
  config.default_plan_name = "default"

  config.automount_routes = true
  config.routes_path = "/pay"
end
