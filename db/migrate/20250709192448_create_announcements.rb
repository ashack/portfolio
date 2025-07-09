class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :message, null: false
      t.string :style, null: false, default: "info"
      t.boolean :dismissible, null: false, default: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.boolean :published, null: false, default: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :announcements, :published
    add_index :announcements, :starts_at
    add_index :announcements, :ends_at
    add_index :announcements, [:published, :starts_at, :ends_at], name: "index_announcements_on_active_status"
  end
end
