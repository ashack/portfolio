class MakeEnterpriseGroupAdminOptional < ActiveRecord::Migration[8.0]
  def change
    change_column_null :enterprise_groups, :admin_id, true
  end
end
