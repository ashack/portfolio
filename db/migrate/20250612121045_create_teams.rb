class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      # Team Identity
      t.string :name, null: false
      t.string :slug, null: false

      # Team Management
      t.bigint :admin_id, null: false
      t.bigint :created_by_id, null: false

      # Subscription & Billing
      t.integer :plan, default: 0
      t.integer :status, default: 0
      t.string :stripe_customer_id
      t.datetime :trial_ends_at
      t.datetime :current_period_end

      # Configuration
      t.json :settings
      t.integer :max_members, default: 5
      t.string :custom_domain

      t.timestamps
    end

    add_index :teams, :slug, unique: true
    add_index :teams, :admin_id
    add_index :teams, :status
    add_index :teams, :created_by_id

    # Add foreign key constraints
    add_foreign_key :teams, :users, column: :admin_id
    add_foreign_key :teams, :users, column: :created_by_id
  end
end
