class EnterpriseGroup < ApplicationRecord
  pay_customer # For enterprise billing

  belongs_to :admin, class_name: "User"
  belongs_to :created_by, class_name: "User"
  belongs_to :plan
  has_many :users, dependent: :restrict_with_error
  has_many :invitations, dependent: :destroy

  enum :status, { active: 0, suspended: 1, cancelled: 2 }

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :admin_id, presence: true
  validates :created_by_id, presence: true
  validates :plan_id, presence: true
  validate :plan_must_be_enterprise

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

  private

  def generate_slug
    return unless name.present?

    base_slug = name.downcase.gsub(/[^a-z0-9\s\-]/, "").gsub(/\s+/, "-").gsub(/^-+|-+$/, "")
    counter = 0
    potential_slug = base_slug

    while EnterpriseGroup.exists?(slug: potential_slug)
      counter += 1
      potential_slug = "#{base_slug}-#{counter}"
    end

    self.slug = potential_slug
  end

  def plan_must_be_enterprise
    return unless plan

    unless plan.plan_segment == "enterprise"
      errors.add(:plan, "must be an enterprise plan")
    end
  end
end
