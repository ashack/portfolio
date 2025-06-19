# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_06_19_111650) do
  create_table "admin_activity_logs", force: :cascade do |t|
    t.integer "admin_user_id", null: false
    t.string "controller", null: false
    t.string "action", null: false
    t.string "method", null: false
    t.string "path", null: false
    t.text "params"
    t.string "ip_address"
    t.text "user_agent"
    t.string "referer"
    t.string "session_id"
    t.string "request_id"
    t.datetime "timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_admin_activity_logs_on_action"
    t.index ["admin_user_id", "timestamp"], name: "index_admin_activity_logs_on_admin_user_id_and_timestamp"
    t.index ["admin_user_id"], name: "index_admin_activity_logs_on_admin_user_id"
    t.index ["controller"], name: "index_admin_activity_logs_on_controller"
    t.index ["ip_address"], name: "index_admin_activity_logs_on_ip_address"
    t.index ["session_id"], name: "index_admin_activity_logs_on_session_id"
    t.index ["timestamp"], name: "index_admin_activity_logs_on_timestamp"
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.integer "visit_id"
    t.integer "user_id"
    t.string "name"
    t.text "properties"
    t.datetime "time"
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.integer "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.string "app_version"
    t.string "os_version"
    t.string "platform"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
    t.index ["visitor_token", "started_at"], name: "index_ahoy_visits_on_visitor_token_and_started_at"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "target_user_id", null: false
    t.string "action", null: false
    t.json "details"
    t.string "ip_address"
    t.string "user_agent", limit: 500
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["target_user_id", "created_at"], name: "index_audit_logs_on_target_user_id_and_created_at"
    t.index ["target_user_id"], name: "index_audit_logs_on_target_user_id"
    t.index ["user_id", "created_at"], name: "index_audit_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "email_change_requests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "new_email", null: false
    t.integer "status", default: 0, null: false
    t.text "reason"
    t.datetime "requested_at", null: false
    t.integer "approved_by_id"
    t.datetime "approved_at"
    t.text "notes"
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approved_by_id"], name: "index_email_change_requests_on_approved_by_id"
    t.index ["new_email"], name: "index_email_change_requests_on_new_email"
    t.index ["requested_at"], name: "index_email_change_requests_on_requested_at"
    t.index ["status"], name: "index_email_change_requests_on_status"
    t.index ["token"], name: "index_email_change_requests_on_token", unique: true
    t.index ["user_id", "status"], name: "index_email_change_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_email_change_requests_on_user_id"
  end

  create_table "enterprise_groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "admin_id", null: false
    t.bigint "created_by_id", null: false
    t.bigint "plan_id", null: false
    t.integer "status", default: 0
    t.string "stripe_customer_id"
    t.datetime "trial_ends_at"
    t.datetime "current_period_end"
    t.json "settings"
    t.integer "max_members", default: 100
    t.string "custom_domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_enterprise_groups_on_admin_id"
    t.index ["created_by_id"], name: "index_enterprise_groups_on_created_by_id"
    t.index ["plan_id"], name: "index_enterprise_groups_on_plan_id"
    t.index ["slug"], name: "index_enterprise_groups_on_slug", unique: true
    t.index ["status"], name: "index_enterprise_groups_on_status"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.string "email", null: false
    t.integer "role", default: 0
    t.string "token", null: false
    t.bigint "invited_by_id", null: false
    t.datetime "accepted_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(email)", name: "index_invitations_on_lower_email"
    t.index ["accepted_at"], name: "index_invitations_on_accepted_at"
    t.index ["email"], name: "index_invitations_on_email"
    t.index ["expires_at"], name: "index_invitations_on_expires_at"
    t.index ["team_id"], name: "index_invitations_on_team_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "pay_charges", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "subscription_id"
    t.string "processor_id", null: false
    t.integer "amount", null: false
    t.string "currency"
    t.integer "application_fee_amount"
    t.integer "amount_refunded"
    t.json "metadata"
    t.json "data"
    t.string "stripe_account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "processor", null: false
    t.string "processor_id"
    t.boolean "default"
    t.json "data"
    t.string "stripe_account"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "deleted_at"], name: "pay_customer_owner_index", unique: true
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "processor", null: false
    t.string "processor_id"
    t.boolean "default"
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
  end

  create_table "pay_payment_methods", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "processor_id", null: false
    t.boolean "default"
    t.string "type"
    t.json "data"
    t.string "stripe_account"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "name", null: false
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.datetime "current_period_start", precision: nil
    t.datetime "current_period_end", precision: nil
    t.datetime "trial_ends_at", precision: nil
    t.datetime "ends_at", precision: nil
    t.boolean "metered"
    t.string "pause_behavior"
    t.datetime "pause_starts_at", precision: nil
    t.datetime "pause_resumes_at", precision: nil
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.json "metadata"
    t.json "data"
    t.string "stripe_account"
    t.string "payment_method_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["metered"], name: "index_pay_subscriptions_on_metered"
    t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.string "processor"
    t.string "event_type"
    t.json "event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "stripe_price_id"
    t.integer "amount_cents", default: 0
    t.string "interval"
    t.integer "max_team_members"
    t.json "features"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "plan_segment", default: "individual", null: false
    t.index ["active"], name: "index_plans_on_active"
    t.index ["plan_segment"], name: "index_plans_on_plan_segment"
    t.check_constraint "plan_segment IN ('individual', 'team', 'enterprise')", name: "valid_plan_segment"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.bigint "admin_id", null: false
    t.bigint "created_by_id", null: false
    t.integer "plan", default: 0
    t.integer "status", default: 0
    t.string "stripe_customer_id"
    t.datetime "trial_ends_at"
    t.datetime "current_period_end"
    t.json "settings"
    t.integer "max_members", default: 5
    t.string "custom_domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_id"], name: "index_teams_on_admin_id"
    t.index ["created_by_id"], name: "index_teams_on_created_by_id"
    t.index ["slug"], name: "index_teams_on_slug", unique: true
    t.index ["status"], name: "index_teams_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer "system_role", default: 0, null: false
    t.integer "user_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.bigint "team_id"
    t.integer "team_role"
    t.string "stripe_customer_id"
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unconfirmed_email"
    t.datetime "locked_at"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.integer "plan_id"
    t.bigint "enterprise_group_id"
    t.integer "enterprise_group_role"
    t.boolean "owns_team", default: false
    t.index "LOWER(email)", name: "index_users_on_lower_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["enterprise_group_id", "enterprise_group_role"], name: "index_users_on_enterprise_associations"
    t.index ["enterprise_group_id"], name: "index_users_on_enterprise_group_id"
    t.index ["last_activity_at"], name: "index_users_on_last_activity_at"
    t.index ["plan_id"], name: "index_users_on_plan_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
    t.index ["team_id", "team_role"], name: "index_users_on_team_associations"
    t.index ["team_id"], name: "index_users_on_team_id"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["user_type", "team_id"], name: "index_users_on_user_type_and_team"
  end

  add_foreign_key "admin_activity_logs", "users", column: "admin_user_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "audit_logs", "users", column: "target_user_id"
  add_foreign_key "email_change_requests", "users"
  add_foreign_key "email_change_requests", "users", column: "approved_by_id"
  add_foreign_key "enterprise_groups", "plans"
  add_foreign_key "enterprise_groups", "users", column: "admin_id"
  add_foreign_key "enterprise_groups", "users", column: "created_by_id"
  add_foreign_key "invitations", "teams"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "teams", "users", column: "admin_id"
  add_foreign_key "teams", "users", column: "created_by_id"
  add_foreign_key "users", "enterprise_groups"
  add_foreign_key "users", "plans"
  add_foreign_key "users", "teams"
end
