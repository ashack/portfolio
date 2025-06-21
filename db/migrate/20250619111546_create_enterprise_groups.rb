class CreateEnterpriseGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :enterprise_groups do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.bigint :admin_id, null: false
      t.bigint :created_by_id, null: false
      t.bigint :plan_id, null: false
      t.integer :status, default: 0
      t.string :stripe_customer_id
      t.datetime :trial_ends_at
      t.datetime :current_period_end
      t.json :settings
      t.integer :max_members, default: 100
      t.string :custom_domain

      t.timestamps
    end

    add_index :enterprise_groups, :slug, unique: true
    add_index :enterprise_groups, :admin_id
    add_index :enterprise_groups, :created_by_id
    add_index :enterprise_groups, :plan_id
    add_index :enterprise_groups, :status

    add_foreign_key :enterprise_groups, :users, column: :admin_id
    add_foreign_key :enterprise_groups, :users, column: :created_by_id
    add_foreign_key :enterprise_groups, :plans
  end
end
