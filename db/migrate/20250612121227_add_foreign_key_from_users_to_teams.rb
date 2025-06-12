class AddForeignKeyFromUsersToTeams < ActiveRecord::Migration[8.0]
  def change
    # Add foreign key constraint from users to teams
    add_foreign_key :users, :teams
  end
end
