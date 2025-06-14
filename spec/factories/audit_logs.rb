FactoryBot.define do
  factory :audit_log do
    user { nil }
    target_user { nil }
    action { "MyString" }
    details { "" }
    ip_address { "MyString" }
    user_agent { "MyString" }
  end
end
