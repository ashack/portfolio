class AddPlanSegmentToPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :plans, :plan_segment, :string, null: false, default: 'individual'
    add_index :plans, :plan_segment

    # Add a check constraint to ensure valid segments
    add_check_constraint :plans, "plan_segment IN ('individual', 'team', 'enterprise')", name: "valid_plan_segment"
  end
end
