class TeamsQuery
  attr_reader :relation

  def initialize(relation = Team.all)
    @relation = relation
  end

  # Eager load all associations
  def with_all_associations
    @relation = @relation.includes(:admin, :created_by, :users)
    self
  end

  # For admin dashboards - includes user count
  def for_admin_index
    @relation = @relation
      .includes(:admin, :created_by)
      .left_joins(:users)
      .group("teams.id")
      .select("teams.*, COUNT(DISTINCT users.id) as cached_users_count")
    self
  end

  # Active teams only
  def active
    @relation = @relation.where(status: "active")
    self
  end

  # By plan type
  def by_plan(plan)
    @relation = @relation.where(plan: plan)
    self
  end

  # Paid plans only
  def paid_only
    @relation = @relation.where.not(plan: "starter")
    self
  end

  # Order
  def newest_first
    @relation = @relation.order(created_at: :desc)
    self
  end

  def by_name
    @relation = @relation.order(:name)
    self
  end

  # Search
  def search(query)
    return self if query.blank?

    @relation = @relation.where("name LIKE ? OR slug LIKE ?", "%#{query}%", "%#{query}%")
    self
  end

  # Execute and return results
  def results
    @relation
  end

  # Delegate array methods to relation
  delegate :count, :any?, :empty?, :first, :last, :each, :map, :pluck, to: :relation
end
