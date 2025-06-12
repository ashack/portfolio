class Plan < ApplicationRecord
  enum :plan_type, { individual: 0, team: 1 }

  validates :name, presence: true
  validates :plan_type, presence: true
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :max_team_members, numericality: { greater_than: 0 }, if: :team?
  validates :interval, inclusion: { in: %w[month year] }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :for_individuals, -> { where(plan_type: "individual") }
  scope :for_teams, -> { where(plan_type: "team") }

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
end
