class PlanPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.super_admin?
        scope.all
      else
        scope.none
      end
    end
  end

  def index?
    super_admin?
  end

  def show?
    super_admin?
  end

  def new?
    super_admin?
  end

  def create?
    super_admin?
  end

  def edit?
    super_admin?
  end

  def update?
    super_admin?
  end

  def destroy?
    super_admin?
  end
end
