class AddEnhancedProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Profile fields
    add_column :users, :avatar_url, :string
    add_column :users, :bio, :text
    add_column :users, :timezone, :string, default: "UTC"
    add_column :users, :locale, :string, default: "en"
    add_column :users, :phone_number, :string

    # Social media links
    add_column :users, :linkedin_url, :string
    add_column :users, :twitter_url, :string
    add_column :users, :github_url, :string
    add_column :users, :website_url, :string

    # Preferences
    add_column :users, :notification_preferences, :json, default: {}
    add_column :users, :profile_visibility, :integer, default: 0

    # Profile completion tracking
    add_column :users, :profile_completed_at, :datetime
    add_column :users, :profile_completion_percentage, :integer, default: 0

    # Two-factor authentication
    add_column :users, :two_factor_enabled, :boolean, default: false
    add_column :users, :two_factor_secret, :string
    add_column :users, :two_factor_backup_codes, :json

    # Indexes for performance
    add_index :users, :timezone
    add_index :users, :profile_visibility
  end
end
