class UsersQuery
  attr_reader :relation

  def initialize(relation = User.all)
    @relation = relation
  end

  # Eager load all common associations
  def with_all_associations
    @relation = @relation.includes(:team, :plan, :enterprise_group, :ahoy_visits)
    self
  end

  # Load for admin dashboards
  def for_admin_index
    @relation = @relation.includes(:team, :plan, :enterprise_group)
    self
  end

  # Load for team member lists
  def for_team_members(team)
    @relation = @relation.where(team: team).includes(:ahoy_visits)
    self
  end

  # Filter by status
  def active
    @relation = @relation.where(status: "active")
    self
  end

  # Filter by user type
  def direct_only
    @relation = @relation.where(user_type: "direct")
    self
  end

  def team_members_only
    @relation = @relation.where(user_type: "invited")
    self
  end

  # Exclude system admins
  def exclude_admins
    @relation = @relation.where.not(system_role: [ "super_admin", "site_admin" ])
    self
  end

  # Recent activity
  def recently_active(days = 7)
    @relation = @relation.where("last_activity_at > ?", days.days.ago)
    self
  end

  # Order
  def newest_first
    @relation = @relation.order(created_at: :desc)
    self
  end

  def by_last_activity
    @relation = @relation.order(last_activity_at: :desc)
    self
  end

  # Execute and return results
  def results
    @relation
  end

  # Delegate array methods to relation
  delegate :count, :any?, :empty?, :first, :last, :each, :map, :pluck, to: :relation
end
