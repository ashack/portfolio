class SubscriptionPolicy < ApplicationPolicy
  def show?
    # Only direct users can view their subscription
    user&.direct? && user&.active?
  end

  def edit?
    # Only direct users can edit their subscription
    user&.direct? && user&.active?
  end

  def update?
    # Only direct users can update their subscription
    user&.direct? && user&.active?
  end

  def destroy?
    # Only direct users can cancel their subscription
    # And only if they're not already on the free plan
    user&.direct? && user&.active? && user&.plan&.present? && !user.plan.free?
  end
end
