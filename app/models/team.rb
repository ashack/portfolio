class Team < ApplicationRecord
  include Pay::Billable # For team billing

  belongs_to :admin, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, dependent: :destroy

  enum :plan, { starter: 0, pro: 1, enterprise: 2 }
  enum :status, { active: 0, suspended: 1, cancelled: 2 }

  validates :name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :admin_id, presence: true
  validates :created_by_id, presence: true

  before_validation :generate_slug, if: :name_changed?

  scope :active, -> { where(status: "active") }

  def to_param
    slug
  end

  def member_count
    users.count
  end

  def can_add_members?
    member_count < max_members
  end

  def plan_features
    case plan
    when "starter"
      [ "team_dashboard", "collaboration", "email_support" ]
    when "pro"
      [ "team_dashboard", "collaboration", "advanced_team_features", "priority_support" ]
    when "enterprise"
      [ "team_dashboard", "collaboration", "advanced_team_features", "enterprise_features", "phone_support" ]
    end
  end

  private

  def generate_slug
    return unless name.present?

    base_slug = name.downcase.gsub(/[^a-z0-9\s\-]/, "").gsub(/\s+/, "-")
    counter = 0
    potential_slug = base_slug

    while Team.exists?(slug: potential_slug)
      counter += 1
      potential_slug = "#{base_slug}-#{counter}"
    end

    self.slug = potential_slug
  end
end
