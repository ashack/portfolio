class AddSettingsFieldsToEnterpriseGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :enterprise_groups, :contact_email, :string
    add_column :enterprise_groups, :contact_phone, :string
    add_column :enterprise_groups, :billing_address, :text
  end
end
