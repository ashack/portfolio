class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || @user == @record || (team_admin? && same_team?)
  end

  def create?
    super_admin?
  end

  def new?
    create?
  end

  def edit?
    super_admin?
  end

  def update?
    super_admin?
  end

  def destroy?
    super_admin? || (team_admin? && same_team?)
  end

  # System role management (only super admins)
  def promote_to_site_admin?
    super_admin? && @record.user? && @user != @record
  end

  def demote_from_site_admin?
    super_admin? && @record.site_admin? && @user != @record
  end

  # Status management (super admins and site admins)
  def set_status?
    admin? && can_manage_status?
  end

  # Account security actions (super admins only)
  def reset_password?
    super_admin? && @user != @record
  end

  def confirm_email?
    super_admin?
  end

  def resend_confirmation?
    super_admin?
  end

  def unlock_account?
    super_admin?
  end

  # User monitoring (admins can view)
  def activity?
    admin?
  end

  def impersonate?
    admin? && @user != @record && can_impersonate?
  end

  # Field-level editing permissions for super admins
  def can_edit_basic_info?
    super_admin?
  end

  def can_edit_email?
    super_admin?
  end

  def can_edit_system_role?
    super_admin? && @user != @record
  end

  def can_edit_status?
    admin? && can_manage_status?
  end

  def can_edit_team_associations?
    false # Team associations should only be managed through team creation/invitation flows
  end

  private

  def team_admin?
    @user&.team_role == "admin"
  end

  def same_team?
    @user&.team_id == @record&.team_id
  end

  def can_manage_status?
    # Super admins can manage any user's status
    return true if super_admin?

    # Site admins can manage status but not for super admins
    return false if @record&.super_admin?

    # Site admins can manage regular users and other site admins
    site_admin?
  end

  def can_impersonate?
    # Super admins can impersonate anyone except other super admins
    if super_admin?
      return !@record&.super_admin?
    end

    # Site admins can impersonate regular users only
    if site_admin?
      return @record&.user?
    end

    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if @user.super_admin?
        scope.all
      elsif @user.site_admin?
        scope.where.not(system_role: "super_admin")
      elsif @user.team_admin?
        scope.where(team_id: @user.team_id)
      else
        scope.none
      end
    end
  end
end
