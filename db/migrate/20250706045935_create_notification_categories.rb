class CreateNotificationCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_categories do |t|
      t.string :name, null: false
      t.string :key, null: false # Unique identifier for the category
      t.text :description
      t.string :icon, default: 'bell' # Phosphor icon name
      t.string :color, default: 'gray' # Tailwind color name
      
      # Scope - who can use this category
      t.string :scope, null: false # 'system', 'team', 'enterprise'
      
      # Owner - who created this category
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      
      # For team/enterprise scoped categories
      t.references :team, foreign_key: true
      t.references :enterprise_group, foreign_key: true
      
      # Settings
      t.boolean :active, default: true
      t.boolean :allow_user_disable, default: true # Can users disable notifications of this type?
      t.string :default_priority, default: 'medium' # low, medium, high, critical
      
      # Email settings
      t.boolean :send_email, default: true
      t.string :email_template # Custom email template name
      
      # Delivery settings
      t.json :delivery_settings, default: {} # Additional settings for delivery
      
      t.timestamps
    end
    
    add_index :notification_categories, :key, unique: true
    add_index :notification_categories, [:scope, :active]
    add_index :notification_categories, [:team_id, :active]
    add_index :notification_categories, [:enterprise_group_id, :active]
    
    # SQLite doesn't support adding CHECK constraints with ALTER TABLE
    # For PostgreSQL or MySQL in production, you can add:
    # 
    # execute <<-SQL
    #   ALTER TABLE notification_categories
    #   ADD CONSTRAINT check_notification_category_scope
    #   CHECK (
    #     (scope = 'system' AND team_id IS NULL AND enterprise_group_id IS NULL) OR
    #     (scope = 'team' AND team_id IS NOT NULL AND enterprise_group_id IS NULL) OR
    #     (scope = 'enterprise' AND team_id IS NULL AND enterprise_group_id IS NOT NULL)
    #   );
    # SQL
    #
    # For SQLite, these constraints are enforced at the model level instead
  end
end