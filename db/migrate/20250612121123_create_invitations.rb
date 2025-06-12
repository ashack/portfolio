class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.bigint :team_id, null: false
      t.string :email, null: false
      t.integer :role, default: 0
      t.string :token, null: false
      t.bigint :invited_by_id, null: false

      t.datetime :accepted_at
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
    add_index :invitations, :team_id

    # Add foreign key constraints
    add_foreign_key :invitations, :teams
    add_foreign_key :invitations, :users, column: :invited_by_id
  end
end
