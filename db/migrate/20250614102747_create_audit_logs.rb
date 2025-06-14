class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :target_user, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.json :details
      t.string :ip_address
      t.string :user_agent, limit: 500

      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
    add_index :audit_logs, [ :user_id, :created_at ]
    add_index :audit_logs, [ :target_user_id, :created_at ]
  end
end
