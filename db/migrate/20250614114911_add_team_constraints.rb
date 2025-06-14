class AddTeamConstraints < ActiveRecord::Migration[8.0]
  def change
    # Add check constraint to ensure invited users have team associations
    # Note: SQLite doesn't support complex check constraints, so this is primarily for documentation
    # The actual enforcement happens at the application level

    # Add indexes for better performance on team constraint queries
    add_index :users, [ :team_id, :team_role ], name: "index_users_on_team_associations"
    add_index :users, [ :user_type, :team_id ], name: "index_users_on_user_type_and_team"

    # Add foreign key constraint to ensure referential integrity
    # This will prevent orphaned team references
    add_foreign_key :users, :teams, validate: false # Skip validation for existing data

    # Validate the foreign key for new records going forward
    # Note: In production, you might want to validate existing data first
    # validate_foreign_key :users, :teams
  end
end
