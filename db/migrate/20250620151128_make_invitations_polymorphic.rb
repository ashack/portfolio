class MakeInvitationsPolymorphic < ActiveRecord::Migration[8.0]
  def change
    # Add polymorphic columns for invitable
    add_reference :invitations, :invitable, polymorphic: true, index: true
    
    # Add invitation type to distinguish between team and enterprise invitations
    add_column :invitations, :invitation_type, :string, default: 'team', null: false
    
    # Migrate existing team_id to invitable
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE invitations 
          SET invitable_type = 'Team', 
              invitable_id = team_id,
              invitation_type = 'team'
          WHERE team_id IS NOT NULL
        SQL
      end
    end
    
    # Make team_id optional (we'll keep it for now for backwards compatibility)
    change_column_null :invitations, :team_id, true
    
    # Add index for invitation type
    add_index :invitations, :invitation_type
  end
end
