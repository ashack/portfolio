# Creates the user_preferences table for storing user-specific settings
# Initially used for pagination preferences per controller
# Can be extended for other user preferences in the future
class CreateUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_preferences do |t|
      # Each user can have exactly one preferences record
      # The unique index ensures one-to-one relationship
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      
      # JSON column for storing pagination settings per controller
      # Structure: { "controller_name" => items_per_page }
      # Example: { "users" => 50, "teams" => 20, "invitations" => 100 }
      t.json :pagination_settings, default: {}

      t.timestamps
    end
  end
end
