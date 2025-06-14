FactoryBot.define do
  factory :admin_activity_log do
    association :admin_user, factory: :user
    controller { "admin/super/users" }
    action { "update" }
    add_attribute(:method) { "PATCH" }
    path { "/admin/super/users/1" }
    params { '{"user":{"status":"active"}}' }
    ip_address { "127.0.0.1" }
    user_agent { "Mozilla/5.0 (Test Browser)" }
    referer { "http://localhost:3000/admin/super/users" }
    session_id { SecureRandom.hex(16) }
    request_id { SecureRandom.uuid }
    timestamp { Time.current }
  end
end
