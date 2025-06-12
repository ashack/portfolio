class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.integer :plan_type, null: false
      t.string :stripe_price_id
      t.integer :amount_cents, default: 0
      t.string :interval

      # Plan Limits
      t.integer :max_team_members
      t.json :features

      t.boolean :active, default: true

      t.timestamps
    end

    add_index :plans, :plan_type
    add_index :plans, :active
  end
end
