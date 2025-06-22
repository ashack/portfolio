# Plan model represents subscription plans for the SaaS application
# Plans are segmented into three types:
# - Individual: For direct users with personal billing
# - Team: For teams with shared features and billing
# - Enterprise: For large organizations (contact sales)
#
# BUSINESS RULES:
# - Plan segments determine available features and billing model
# - Team plans have member limits
# - Enterprise plans require sales contact (no self-service)
# - Free plans have amount_cents = 0
class Plan < ApplicationRecord
  # Plan segment determines who can use this plan
  # - individual: Direct users only
  # - team: Teams only (with member limits)
  # - enterprise: Enterprise organizations only
  enum :plan_segment, { individual: "individual", team: "team", enterprise: "enterprise" }, prefix: true

  # ========================================================================
  # VALIDATIONS
  # ========================================================================

  validates :name, presence: true
  validates :plan_segment, presence: true
  
  # Price validation - 0 for free plans
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  
  # Team plans must specify member limit
  validates :max_team_members, numericality: { greater_than: 0 }, if: :plan_segment_team?
  
  # Billing interval for paid plans
  validates :interval, inclusion: { in: %w[month year] }, allow_nil: true

  # ========================================================================
  # SCOPES
  # ========================================================================

  # Only show active plans
  scope :active, -> { where(active: true) }
  
  # Filter by plan segment
  scope :for_individuals, -> { where(plan_segment: "individual") }
  scope :for_teams, -> { where(plan_segment: "team") }
  scope :for_enterprise, -> { where(plan_segment: "enterprise") }
  
  # Plans available for self-service signup (excludes enterprise)
  scope :available_for_signup, -> { active.where.not(plan_segment: "enterprise") }
  
  # Generic segment filter
  scope :by_segment, ->(segment) { where(plan_segment: segment) }

  # ========================================================================
  # PUBLIC INSTANCE METHODS
  # ========================================================================

  # Checks if this is a free plan
  def free?
    amount_cents == 0
  end

  # Returns human-readable price string
  # Examples: "Free", "$19/month", "$99/year"
  def formatted_price
    if free?
      "Free"
    else
      "$#{amount_cents / 100.0}/#{interval}"
    end
  end

  # Checks if plan includes a specific feature
  # Features are stored as JSON array in database
  def has_feature?(feature)
    features&.include?(feature)
  end

  # Enterprise plans require contacting sales
  def contact_sales?
    plan_segment_enterprise?
  end

  # Alias for clarity in views
  def contact_sales_only?
    plan_segment_enterprise?
  end

  # Returns display name for plan segment
  # Used in admin interfaces and plan selection
  def segment_display_name
    case plan_segment
    when "individual"
      "Direct user signup"
    when "team"
      "Team signup"
    when "enterprise"
      "Contact sales"
    end
  end

  # Returns user-friendly segment name
  # Used in pricing pages and user interfaces
  def display_segment
    case plan_segment
    when "individual"
      "Individual"
    when "team"
      "Team"
    when "enterprise"
      "Enterprise (Contact Sales)"
    end
  end
end
