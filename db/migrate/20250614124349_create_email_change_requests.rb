class CreateEmailChangeRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :email_change_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :new_email, null: false
      t.integer :status, default: 0, null: false
      t.text :reason
      t.datetime :requested_at, null: false
      t.references :approved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.text :notes
      t.string :token, null: false

      t.timestamps
    end

    # Add indexes for performance
    add_index :email_change_requests, :status
    add_index :email_change_requests, :new_email
    add_index :email_change_requests, :token, unique: true
    add_index :email_change_requests, :requested_at
    add_index :email_change_requests, [ :user_id, :status ]
  end
end
