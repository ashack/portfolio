FactoryBot.define do
  factory :email_change_request do
    user { nil }
    new_email { "MyString" }
    status { 1 }
    reason { "MyText" }
    requested_at { "2025-06-14 18:13:49" }
    approved_by { nil }
    approved_at { "2025-06-14 18:13:49" }
    notes { "MyText" }
  end
end
