class SelfEditValidator
  def self.validate_no_self_role_edit(admin_user, target_user, params)
    errors = []

    # Check if admin is trying to edit their own system role
    if admin_user.id == target_user.id && params.key?(:system_role)
      errors << "You cannot change your own system role"
    end

    # Check if admin is trying to edit their own status
    if admin_user.id == target_user.id && params.key?(:status)
      errors << "You cannot change your own account status"
    end

    errors
  end

  def self.validate_role_transition(from_role, to_role)
    valid_transitions = {
      "user" => %w[site_admin super_admin],
      "site_admin" => %w[user super_admin],
      "super_admin" => %w[user site_admin]
    }

    return true if valid_transitions[from_role]&.include?(to_role)

    false
  end

  def self.safe_for_self_edit?(field)
    safe_fields = %w[first_name last_name email]
    safe_fields.include?(field.to_s)
  end
end
