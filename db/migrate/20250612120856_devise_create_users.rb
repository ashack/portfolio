# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      
      # Name fields
      t.string :first_name
      t.string :last_name

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at

      # System Role (for platform administration)
      t.integer :system_role, default: 0, null: false
      
      # User Type & Status
      t.integer :user_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      
      # Team Association (only for invited users)
      t.bigint :team_id
      t.integer :team_role
      
      # Individual Billing (only for direct users)
      t.string :stripe_customer_id
      
      # Activity Tracking
      t.datetime :last_activity_at

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :team_id
    add_index :users, :status
    add_index :users, :last_activity_at
  end
end