class AddEmailIndexesToTables < ActiveRecord::Migration[8.0]
  def change
    # Add case-insensitive index on users.email for better performance
    # Note: The existing unique index on email will remain for exact matches
    add_index :users, "LOWER(email)", name: "index_users_on_lower_email"

    # Add case-insensitive index on invitations.email for better performance
    add_index :invitations, "LOWER(email)", name: "index_invitations_on_lower_email"

    # Add regular indexes for invitation status queries
    add_index :invitations, :accepted_at, name: "index_invitations_on_accepted_at"
    add_index :invitations, :expires_at, name: "index_invitations_on_expires_at"
  end
end
