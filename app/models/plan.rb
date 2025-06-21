class Plan < ApplicationRecord
  enum :plan_segment, { individual: "individual", team: "team", enterprise: "enterprise" }, prefix: true

  validates :name, presence: true
  validates :plan_segment, presence: true
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :max_team_members, numericality: { greater_than: 0 }, if: :plan_segment_team?
  validates :interval, inclusion: { in: %w[month year] }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :for_individuals, -> { where(plan_segment: "individual") }
  scope :for_teams, -> { where(plan_segment: "team") }
  scope :for_enterprise, -> { where(plan_segment: "enterprise") }
  scope :available_for_signup, -> { active.where.not(plan_segment: "enterprise") }
  scope :by_segment, ->(segment) { where(plan_segment: segment) }

  def free?
    amount_cents == 0
  end

  def formatted_price
    if free?
      "Free"
    else
      "$#{amount_cents / 100.0}/#{interval}"
    end
  end

  def has_feature?(feature)
    features&.include?(feature)
  end

  def contact_sales?
    plan_segment_enterprise?
  end

  def contact_sales_only?
    plan_segment_enterprise?
  end

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
