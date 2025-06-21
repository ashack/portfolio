class RemovePlanTypeFromPlans < ActiveRecord::Migration[8.0]
  def change
    remove_index :plans, :plan_type if index_exists?(:plans, :plan_type)
    remove_column :plans, :plan_type, :integer
  end
end
