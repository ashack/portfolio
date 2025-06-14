require "ostruct"

class Users::UpdateService
  def initialize(admin_user, target_user, user_params, request = nil)
    @admin_user = admin_user
    @target_user = target_user
    @user_params = user_params
    @request = request
  end

  def call
    return failure("Unauthorized") unless can_update_user?
    return failure("Cannot edit your own system role") if editing_own_system_role?
    return failure("Cannot edit your own account") if editing_own_account_critical_fields?
    return failure("Invalid user type change") if invalid_user_type_change?
    return failure("Invalid system role change") if invalid_system_role_change?

    # Additional email validation before attempting update
    if email_validation_error = validate_email_update
      return failure(email_validation_error)
    end

    # Validate team constraints before attempting update
    if team_constraint_error = validate_team_constraints
      return failure(team_constraint_error)
    end

    @target_user.transaction do
      old_attributes = capture_old_attributes

      # Set current admin for model validation
      Thread.current[:current_admin_user] = @admin_user

      if @target_user.update(@user_params)
        log_user_changes(old_attributes)
        send_notifications_if_needed(old_attributes)
        success(@target_user)
      else
        failure(@target_user.errors.full_messages.join(", "))
      end
    ensure
      # Clean up thread-local variable
      Thread.current[:current_admin_user] = nil
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def can_update_user?
    @admin_user.super_admin?
  end

  def editing_own_system_role?
    @admin_user.id == @target_user.id && @user_params.key?(:system_role)
  end

  def editing_own_account_critical_fields?
    return false unless @admin_user.id == @target_user.id

    # List of critical fields that admins shouldn't edit on their own account
    critical_fields = [ :system_role, :status ]

    critical_fields.any? { |field| @user_params.key?(field) }
  end

  def invalid_user_type_change?
    # Prevent changing user_type as it's a core business rule
    @user_params.key?(:user_type) && @user_params[:user_type] != @target_user.user_type
  end

  def invalid_system_role_change?
    return false unless @user_params.key?(:system_role)

    new_role = @user_params[:system_role]

    # Prevent invalid role transitions
    case @target_user.system_role
    when "super_admin"
      # Super admins can only be changed by other super admins, and not themselves
      return true if @admin_user.id == @target_user.id
      # Only allow demotion to site_admin or user
      return true unless %w[site_admin user].include?(new_role)
    when "site_admin"
      # Site admins can be promoted to super_admin or demoted to user
      return true unless %w[super_admin user].include?(new_role)
    when "user"
      # Regular users can be promoted to site_admin or super_admin
      return true unless %w[site_admin super_admin].include?(new_role)
    end

    false
  end

  def validate_email_update
    return nil unless @user_params.key?(:email)

    new_email = @user_params[:email]&.downcase&.strip
    current_email = @target_user.email&.downcase

    # Skip validation if email hasn't actually changed
    return nil if new_email == current_email

    # Validate email format
    unless new_email =~ URI::MailTo::EMAIL_REGEXP
      return "Email must be a valid email address"
    end

    # Check for conflicts with other users (case-insensitive)
    if User.where("LOWER(email) = ? AND id != ?", new_email, @target_user.id).exists?
      return "Email is already taken by another user"
    end

    # Check for conflicts with pending invitations
    pending_invitation = Invitation.pending.active.find_by("LOWER(email) = ?", new_email)
    if pending_invitation
      return "Email conflicts with pending team invitation for #{pending_invitation.team.name}"
    end

    nil
  end

  def validate_team_constraints
    return nil unless team_association_being_changed?

    # Prevent removing team associations for invited users
    if @target_user.invited? && removing_team_association?
      return "Cannot remove team association from invited user - this would violate data integrity"
    end

    # Prevent adding team associations to direct users
    if @target_user.direct? && adding_team_association?
      return "Cannot add team association to direct user - this violates the dual-track architecture"
    end

    # Validate team role changes don't break team structure
    if @user_params.key?(:team_role) && @user_params[:team_role] != @target_user.team_role
      if team_role_change_error = validate_team_role_change
        return team_role_change_error
      end
    end

    # Validate team changes maintain admin relationships
    if @user_params.key?(:team_id) && @user_params[:team_id] != @target_user.team_id
      if team_change_error = validate_team_change
        return team_change_error
      end
    end

    nil
  end

  def team_association_being_changed?
    @user_params.key?(:team_id) || @user_params.key?(:team_role)
  end

  def removing_team_association?
    (@user_params.key?(:team_id) && @user_params[:team_id].blank?) ||
    (@user_params.key?(:team_role) && @user_params[:team_role].blank?)
  end

  def adding_team_association?
    (@user_params.key?(:team_id) && @user_params[:team_id].present? && @target_user.team_id.blank?) ||
    (@user_params.key?(:team_role) && @user_params[:team_role].present? && @target_user.team_role.blank?)
  end

  def validate_team_role_change
    new_role = @user_params[:team_role]
    old_role = @target_user.team_role

    # Prevent demoting the last admin
    if old_role == "admin" && new_role == "member" && @target_user.team.present?
      admin_count = @target_user.team.users.where(team_role: "admin").where.not(id: @target_user.id).count
      if admin_count == 0
        return "Cannot change role from admin to member - team must have at least one admin"
      end
    end

    # Prevent removing team admin designation if they are the designated admin
    if old_role == "admin" && @target_user.team&.admin_id == @target_user.id
      return "Cannot change role - user is the designated team admin"
    end

    nil
  end

  def validate_team_change
    new_team_id = @user_params[:team_id]
    old_team = @target_user.team

    # Validate new team exists
    if new_team_id.present? && !Team.exists?(new_team_id)
      return "Cannot assign user to team - team does not exist"
    end

    # Check if user is leaving a team where they are the designated admin
    if old_team&.admin_id == @target_user.id && new_team_id != old_team.id
      return "Cannot move user - they are the designated admin of their current team"
    end

    # Check team member limits for new team
    if new_team_id.present?
      new_team = Team.find(new_team_id)
      if new_team.users.count >= new_team.max_members
        return "Cannot assign user to team - team has reached maximum member limit of #{new_team.max_members}"
      end
    end

    nil
  end

  def capture_old_attributes
    {
      first_name: @target_user.first_name,
      last_name: @target_user.last_name,
      email: @target_user.email,
      system_role: @target_user.system_role,
      status: @target_user.status
    }
  end

  def log_user_changes(old_attributes)
    changes = {}

    old_attributes.each do |key, old_value|
      new_value = @target_user.send(key)
      changes[key] = { from: old_value, to: new_value } if old_value != new_value
    end

    if changes.any?
      AuditLogService.log_user_update(
        admin_user: @admin_user,
        target_user: @target_user,
        changes: changes,
        request: @request
      )
      Rails.logger.info "[ADMIN ACTION] #{@admin_user.email} updated user #{@target_user.email}: #{changes}"
    end
  end

  def send_notifications_if_needed(old_attributes)
    changes = {}

    old_attributes.each do |key, old_value|
      new_value = @target_user.send(key)
      changes[key] = { from: old_value, to: new_value } if old_value != new_value
    end

    # Send notifications for critical changes
    if changes.any?
      UserNotificationService.notify_critical_changes(@target_user, changes, @admin_user)
    end
  end

  def success(user)
    OpenStruct.new(success?: true, user: user)
  end

  def failure(message)
    OpenStruct.new(success?: false, error: message)
  end
end
