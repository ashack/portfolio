class AddTermsAndPrivacyAcceptanceToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :terms_accepted, :boolean, default: false, null: false
    add_column :users, :privacy_accepted, :boolean, default: false, null: false
  end
end
