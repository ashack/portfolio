class AuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :target_user, class_name: "User"

  validates :action, presence: true
  validates :user_id, presence: true
  validates :target_user_id, presence: true

  # Scopes for common queries
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_admin, ->(user_id) { where(user_id: user_id) }
  scope :for_user, ->(target_user_id) { where(target_user_id: target_user_id) }
  scope :today, -> { where("created_at >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("created_at >= ?", Time.current.beginning_of_week) }
  scope :this_month, -> { where("created_at >= ?", Time.current.beginning_of_month) }
  scope :by_category, ->(category) { where(action: send("#{category.upcase}_ACTIONS")) }
  scope :critical_actions, -> { where(action: SECURITY_ACTIONS + [ "user_delete", "team_delete" ]) }
  scope :with_ip, ->(ip) { where(ip_address: ip) }

  # Action types organized by category
  USER_MANAGEMENT_ACTIONS = %w[
    user_create
    user_update
    user_delete
    status_change
    role_change
    email_change
  ].freeze

  SECURITY_ACTIONS = %w[
    password_reset
    account_unlock
    email_confirm
    resend_confirmation
    login_attempt_reset
    security_lock
  ].freeze

  ADMIN_ACTIONS = %w[
    impersonate
    impersonate_end
    admin_login
    admin_logout
    permissions_change
    system_setting_change
    email_change_requested
    email_change_approved
    email_change_rejected
  ].freeze

  TEAM_ACTIONS = %w[
    team_create
    team_update
    team_delete
    team_member_add
    team_member_remove
    team_role_change
    invitation_send
    invitation_revoke
    invitation_resend
  ].freeze

  SYSTEM_ACTIONS = %w[
    data_export
    system_backup
    maintenance_mode
    bulk_operation
    critical_system_change
  ].freeze

  ACTION_TYPES = (
    USER_MANAGEMENT_ACTIONS +
    SECURITY_ACTIONS +
    ADMIN_ACTIONS +
    TEAM_ACTIONS +
    SYSTEM_ACTIONS
  ).freeze

  validates :action, inclusion: { in: ACTION_TYPES }

  def admin_name
    user.full_name.presence || user.email
  end

  def target_user_name
    target_user.full_name.presence || target_user.email
  end

  def action_category
    case action
    when *USER_MANAGEMENT_ACTIONS
      "User Management"
    when *SECURITY_ACTIONS
      "Security"
    when *ADMIN_ACTIONS
      "Admin"
    when *TEAM_ACTIONS
      "Team Management"
    when *SYSTEM_ACTIONS
      "System"
    else
      "Other"
    end
  end

  def action_severity
    case action
    when "user_delete", "team_delete", "critical_system_change"
      "critical"
    when *SECURITY_ACTIONS, "permissions_change", "system_setting_change"
      "high"
    when "role_change", "status_change", "team_member_remove"
      "medium"
    else
      "low"
    end
  end

  def action_icon
    case action_category
    when "User Management"
      "user"
    when "Security"
      "shield"
    when "Admin"
      "key"
    when "Team Management"
      "users"
    when "System"
      "cog"
    else
      "activity"
    end
  end

  def time_ago_in_words
    ActionController::Base.helpers.time_ago_in_words(created_at)
  end

  # Class methods for analytics
  def self.activity_summary(timeframe = :today)
    logs = send(timeframe)
    {
      total_actions: logs.count,
      unique_admins: logs.distinct.count(:user_id),
      critical_actions: logs.critical_actions.count,
      most_active_admin: logs.group(:user_id).count.max_by { |_, count| count }&.first,
      action_breakdown: logs.group(:action).count,
      category_breakdown: logs.group_by(&:action_category).transform_values(&:count)
    }
  end

  def self.admin_activity_report(admin_user, timeframe = :today)
    logs = by_admin(admin_user.id).send(timeframe)
    {
      admin: admin_user,
      total_actions: logs.count,
      actions_by_type: logs.group(:action).count,
      recent_activities: logs.recent.limit(10),
      critical_actions: logs.critical_actions.count
    }
  end

  def formatted_details
    return {} unless details.present?

    case action
    when "user_update"
      format_user_update_details
    when "status_change"
      format_status_change_details
    when "role_change"
      format_role_change_details
    else
      details
    end
  end

  private

  def format_user_update_details
    return details unless details["changes"].present?

    changes = details["changes"]
    formatted = {}

    changes.each do |field, change_data|
      formatted[field.humanize] = "#{change_data['from']} → #{change_data['to']}"
    end

    formatted
  end

  def format_status_change_details
    {
      "Status Change" => "#{details['old_status']} → #{details['new_status']}",
      "Timestamp" => details["timestamp"]
    }
  end

  def format_role_change_details
    {
      "Role Change" => "#{details['old_role']} → #{details['new_role']}",
      "Timestamp" => details["timestamp"]
    }
  end
end
