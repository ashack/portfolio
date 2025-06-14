class AdminActivityLog < ApplicationRecord
  belongs_to :admin_user, class_name: "User"

  validates :controller, presence: true
  validates :action, presence: true
  validates :method, presence: true
  validates :path, presence: true
  validates :timestamp, presence: true

  # Scopes for common queries
  scope :recent, -> { order(timestamp: :desc) }
  scope :by_controller, ->(controller) { where(controller: controller) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_method, ->(method) { where(method: method) }
  scope :by_admin, ->(admin_user_id) { where(admin_user_id: admin_user_id) }
  scope :today, -> { where("timestamp >= ?", Time.current.beginning_of_day) }
  scope :this_week, -> { where("timestamp >= ?", Time.current.beginning_of_week) }
  scope :this_month, -> { where("timestamp >= ?", Time.current.beginning_of_month) }
  scope :by_ip, ->(ip_address) { where(ip_address: ip_address) }

  # Activity categorization
  CRITICAL_CONTROLLERS = %w[admin/super admin/site teams].freeze
  CRITICAL_ACTIONS = %w[create update destroy delete impersonate set_status promote demote].freeze

  def critical_activity?
    CRITICAL_CONTROLLERS.any? { |ctrl| controller&.include?(ctrl) } &&
    CRITICAL_ACTIONS.include?(action)
  end

  def admin_name
    admin_user.full_name.presence || admin_user.email
  end

  def controller_category
    case controller
    when /admin\/super/
      "Super Admin"
    when /admin\/site/
      "Site Admin"
    when /teams/
      "Team Management"
    when /users/
      "User Management"
    else
      "Other"
    end
  end

  def time_ago_in_words
    ActionController::Base.helpers.time_ago_in_words(timestamp)
  end

  def parsed_params
    return {} if params.blank?

    begin
      JSON.parse(params)
    rescue JSON::ParserError
      {}
    end
  end

  def filtered_params_summary
    parsed = parsed_params
    return "No parameters" if parsed.empty?

    # Show only non-sensitive keys
    sensitive_keys = %w[password password_confirmation authenticity_token]
    safe_params = parsed.except(*sensitive_keys)

    safe_params.keys.first(3).join(", ") + (safe_params.size > 3 ? "..." : "")
  end

  # Class methods for analytics
  def self.activity_summary(timeframe = :today)
    logs = send(timeframe)
    {
      total_activities: logs.count,
      unique_admins: logs.distinct.count(:admin_user_id),
      critical_activities: logs.select(&:critical_activity?).count,
      controller_breakdown: logs.group(:controller).count,
      action_breakdown: logs.group(:action).count,
      method_breakdown: logs.group(:method).count
    }
  end

  def self.admin_activity_report(admin_user, timeframe = :today)
    logs = by_admin(admin_user.id).send(timeframe)
    {
      admin: admin_user,
      total_activities: logs.count,
      controllers_accessed: logs.distinct.count(:controller),
      recent_activities: logs.recent.limit(10),
      critical_activities: logs.select(&:critical_activity?).count,
      unique_ips: logs.distinct.count(:ip_address)
    }
  end

  def self.security_report(timeframe = :today)
    logs = send(timeframe)
    critical_logs = logs.select(&:critical_activity?)

    {
      timeframe: timeframe,
      total_critical_activities: critical_logs.count,
      admins_with_critical_activity: critical_logs.map(&:admin_user_id).uniq.count,
      suspicious_activity: detect_suspicious_patterns(logs),
      ip_analysis: analyze_ip_patterns(logs)
    }
  end

  private

  def self.detect_suspicious_patterns(logs)
    suspicious = []

    # Check for rapid activity from same admin
    logs.group(:admin_user_id).each do |admin_id, admin_logs|
      recent_count = admin_logs.select { |log| log.timestamp > 1.minute.ago }.count
      if recent_count > 20
        suspicious << {
          type: "rapid_activity",
          admin_id: admin_id,
          count: recent_count,
          timeframe: "1_minute"
        }
      end
    end

    # Check for activity from new IP addresses
    logs.group(:admin_user_id).each do |admin_id, admin_logs|
      ips = admin_logs.map(&:ip_address).uniq
      historical_ips = AdminActivityLog.where(admin_user_id: admin_id)
                                      .where("timestamp < ?", 1.day.ago)
                                      .distinct
                                      .pluck(:ip_address)

      new_ips = ips - historical_ips
      if new_ips.any?
        suspicious << {
          type: "new_ip_address",
          admin_id: admin_id,
          new_ips: new_ips
        }
      end
    end

    suspicious
  end

  def self.analyze_ip_patterns(logs)
    ip_stats = logs.group(:ip_address).count
    {
      unique_ips: ip_stats.keys.count,
      most_active_ip: ip_stats.max_by { |_, count| count }&.first,
      ip_distribution: ip_stats
    }
  end
end
