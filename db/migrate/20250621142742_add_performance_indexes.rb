class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # User activity and status indexes
    # Skip :last_activity_at - already exists
    add_index :users, [ :status, :last_activity_at ], name: 'index_users_on_status_and_activity', if_not_exists: true
    add_index :users, [ :team_id, :status ], name: 'index_users_on_team_and_status', if_not_exists: true
    # Skip [:team_id, :team_role] - similar index exists

    # Team status and lookups
    # Skip :status - already exists
    add_index :teams, [ :status, :created_at ], name: 'index_teams_on_status_and_created', if_not_exists: true

    # Enterprise group indexes
    add_index :enterprise_groups, :status, if_not_exists: true
    add_index :enterprise_groups, [ :status, :created_at ], name: 'index_enterprise_groups_on_status_and_created', if_not_exists: true

    # Invitation performance indexes
    add_index :invitations, :expires_at, if_not_exists: true
    add_index :invitations, [ :invitable_type, :invitable_id, :accepted_at ],
              name: 'index_invitations_on_invitable_and_accepted', if_not_exists: true
    add_index :invitations, [ :email, :accepted_at ], name: 'index_invitations_on_email_and_accepted', if_not_exists: true

    # Composite indexes for common queries
    add_index :users, [ :email, :status ], name: 'index_users_on_email_and_status', if_not_exists: true
    add_index :teams, [ :slug, :status ], name: 'index_teams_on_slug_and_status', if_not_exists: true
    add_index :enterprise_groups, [ :slug, :status ], name: 'index_enterprise_groups_on_slug_and_status', if_not_exists: true

    # Plan lookups
    add_index :plans, [ :plan_segment, :active ], name: 'index_plans_on_segment_and_active', if_not_exists: true

    # Audit log performance
    add_index :audit_logs, [ :user_id, :created_at ], name: 'index_audit_logs_on_user_and_created', if_not_exists: true
    add_index :audit_logs, [ :target_user_id, :created_at ], name: 'index_audit_logs_on_target_user_and_created', if_not_exists: true
    add_index :audit_logs, [ :action, :created_at ], name: 'index_audit_logs_on_action_and_created', if_not_exists: true
  end
end
