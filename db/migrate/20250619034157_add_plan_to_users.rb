class AddPlanToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :plan, null: true, foreign_key: true
  end
end
