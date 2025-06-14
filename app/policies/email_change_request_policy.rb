class EmailChangeRequestPolicy < ApplicationPolicy
  def index?
    true # Users can see their own requests, admins can see requests they can manage
  end

  def show?
    # Users can view their own requests
    return true if @user == @record.user

    # Super admins can view any request
    return true if super_admin?

    # Team admins can view requests from their team members
    return true if team_admin? && same_team?

    false
  end

  def create?
    true # Any authenticated user can create a request
  end

  def approve?
    can_manage_request?
  end

  def reject?
    can_manage_request?
  end

  private

  def can_manage_request?
    return false unless @record.pending?
    return false if @record.expired?

    # Super admins can manage any request
    return true if super_admin?

    # Team admins can manage requests from their team members
    return true if team_admin? && same_team?

    false
  end

  def team_admin?
    @user&.team_role == "admin"
  end

  def same_team?
    @user&.team_id == @record&.user&.team_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if @user.super_admin?
        # Super admins can see all requests
        scope.all
      elsif @user.team_admin?
        # Team admins can see requests from their team members
        scope.joins(:user).where(users: { team_id: @user.team_id })
      else
        # Regular users can only see their own requests
        scope.where(user: @user)
      end
    end
  end
end
