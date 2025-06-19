class UpdateUsersForEnterpriseGroups < ActiveRecord::Migration[8.0]
  def change
    # Add enterprise group association
    add_column :users, :enterprise_group_id, :bigint
    add_column :users, :enterprise_group_role, :integer
    add_column :users, :owns_team, :boolean, default: false

    # Add indexes
    add_index :users, :enterprise_group_id
    add_index :users, [ :enterprise_group_id, :enterprise_group_role ], name: 'index_users_on_enterprise_associations'

    # Add foreign key
    add_foreign_key :users, :enterprise_groups

    # Update user_type to support enterprise users
    # Note: SQLite doesn't support check constraints in the same way as PostgreSQL
    # The enum in the model will handle the validation
  end
end
