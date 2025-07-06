class NotificationCategory < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: 'User'
  belongs_to :team, optional: true
  belongs_to :enterprise_group, optional: true
  
  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :key, presence: true, uniqueness: true, 
            format: { with: /\A[a-z0-9_]+\z/, message: "must be lowercase letters, numbers, and underscores only" }
  validates :scope, presence: true, inclusion: { in: %w[system team enterprise] }
  validates :icon, presence: true
  validates :color, presence: true, inclusion: { 
    in: %w[gray red yellow green blue indigo purple pink],
    message: "must be a valid Tailwind color"
  }
  validates :default_priority, inclusion: { in: %w[low medium high critical] }
  
  # Validate scope associations
  validates :team_id, presence: true, if: -> { scope == 'team' }
  validates :team_id, absence: true, unless: -> { scope == 'team' }
  validates :enterprise_group_id, presence: true, if: -> { scope == 'enterprise' }
  validates :enterprise_group_id, absence: true, unless: -> { scope == 'enterprise' }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :system_wide, -> { where(scope: 'system') }
  scope :for_team, ->(team) { where(scope: 'team', team: team) }
  scope :for_enterprise, ->(enterprise_group) { where(scope: 'enterprise', enterprise_group: enterprise_group) }
  
  # Get available categories for a user
  def self.available_for(user)
    categories = active.system_wide
    
    if user.team.present?
      categories = categories.or(active.for_team(user.team))
    end
    
    if user.enterprise_group.present?
      categories = categories.or(active.for_enterprise(user.enterprise_group))
    end
    
    categories.order(:name)
  end
  
  # Check if a user can manage this category
  def can_be_managed_by?(user)
    case scope
    when 'system'
      user.super_admin?
    when 'team'
      user.super_admin? || (user.team_id == team_id && user.team_admin?)
    when 'enterprise'
      user.super_admin? || (user.enterprise_group_id == enterprise_group_id && user.enterprise_admin?)
    else
      false
    end
  end
  
  # Generate a unique key from name
  def self.generate_key(name, scope_prefix = nil)
    base_key = name.downcase.gsub(/[^a-z0-9]+/, '_').gsub(/^_|_$/, '')
    key = scope_prefix ? "#{scope_prefix}_#{base_key}" : base_key
    
    # Ensure uniqueness
    counter = 1
    while exists?(key: key)
      key = "#{base_key}_#{counter}"
      counter += 1
    end
    
    key
  end
  
  # Icon helpers
  def icon_class
    "text-#{color}-600"
  end
  
  def bg_class
    "bg-#{color}-100"
  end
  
  # Create default categories
  def self.create_defaults!
    # System-wide categories
    system_categories = [
      {
        name: 'Security Alerts',
        key: 'security_alerts',
        description: 'Important security notifications that cannot be disabled',
        icon: 'shield-warning',
        color: 'red',
        allow_user_disable: false,
        default_priority: 'critical',
        send_email: true
      },
      {
        name: 'Account Updates',
        key: 'account_updates',
        description: 'Notifications about account changes and updates',
        icon: 'user-circle',
        color: 'blue',
        allow_user_disable: true,
        default_priority: 'medium'
      },
      {
        name: 'System Announcements',
        key: 'system_announcements',
        description: 'Platform-wide announcements and updates',
        icon: 'megaphone',
        color: 'purple',
        allow_user_disable: true,
        default_priority: 'medium'
      },
      {
        name: 'Billing & Payments',
        key: 'billing_payments',
        description: 'Payment receipts, subscription updates, and billing notifications',
        icon: 'credit-card',
        color: 'green',
        allow_user_disable: false,
        default_priority: 'high'
      }
    ]
    
    admin_user = User.find_by(system_role: 'super_admin') || User.first
    
    system_categories.each do |attrs|
      find_or_create_by!(key: attrs[:key]) do |category|
        category.attributes = attrs.merge(
          scope: 'system',
          created_by: admin_user
        )
      end
    end
  end
end