class CreateAdminActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_activity_logs do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :users }
      t.string :controller, null: false
      t.string :action, null: false
      t.string :method, null: false
      t.string :path, null: false
      t.text :params
      t.string :ip_address
      t.text :user_agent
      t.string :referer
      t.string :session_id
      t.string :request_id
      t.datetime :timestamp, null: false

      t.timestamps
    end

    # Add indexes for performance (admin_user_id index already created by t.references)
    add_index :admin_activity_logs, :timestamp
    add_index :admin_activity_logs, [ :admin_user_id, :timestamp ]
    add_index :admin_activity_logs, :controller
    add_index :admin_activity_logs, :action
    add_index :admin_activity_logs, :ip_address
    add_index :admin_activity_logs, :session_id
  end
end
