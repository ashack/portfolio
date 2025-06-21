class PlanMigrationPolicy < ApplicationPolicy
  def create?
    user.direct? && user.active?
  end
end
