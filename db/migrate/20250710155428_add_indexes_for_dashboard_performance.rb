class AddIndexesForDashboardPerformance < ActiveRecord::Migration[8.0]
  def change
    # Add composite index for notification queries
    add_index :noticed_notifications, [:recipient_id, :recipient_type, :created_at], 
              name: 'index_notifications_on_recipient_and_created_at',
              if_not_exists: true
    
    # Add index for unread notifications count
    add_index :noticed_notifications, [:recipient_id, :recipient_type, :read_at], 
              name: 'index_notifications_on_recipient_and_read_status',
              if_not_exists: true
    
    # Add index for teams ordered by created_at
    add_index :teams, [:created_at, :status], 
              name: 'index_teams_on_created_at_and_status',
              if_not_exists: true
    
    # Add index for users excluding super admins
    add_index :users, [:system_role, :created_at], 
              name: 'index_users_on_system_role_and_created_at',
              if_not_exists: true
    
    # Add index for users by last activity
    add_index :users, [:system_role, :last_activity_at], 
              name: 'index_users_on_system_role_and_last_activity',
              if_not_exists: true
  end
end
