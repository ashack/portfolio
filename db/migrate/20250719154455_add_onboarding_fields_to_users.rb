class AddOnboardingFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :onboarding_completed, :boolean, default: false, null: false
    add_column :users, :onboarding_step, :string
    
    # Add index for performance when filtering users who need onboarding
    add_index :users, :onboarding_completed
    
    # Set existing direct users as having completed onboarding (they already have plans)
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users 
          SET onboarding_completed = true 
          WHERE user_type = 'direct' AND plan_id IS NOT NULL
        SQL
      end
    end
  end
end
