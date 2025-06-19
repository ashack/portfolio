require "ostruct"

class Teams::CreationService
  def initialize(super_admin, team_params, admin_user)
    @super_admin = super_admin
    @team_params = team_params
    @admin_user = admin_user
  end

  def call
    return failure("Only super admins can create teams") unless @super_admin.super_admin?
    return failure("Admin user must exist") unless @admin_user&.persisted?
    return failure("User already has a team") if @admin_user.team.present?
    return failure("Only invited users can be assigned as team admins") unless @admin_user.invited?

    Team.transaction do
      team = create_team
      assign_admin(team)
      setup_billing(team)
      send_notifications(team)

      success(team)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def create_team
    Team.create!(
      name: @team_params[:name],
      admin: @admin_user,
      created_by: @super_admin,
      plan: @team_params[:plan] || "starter",
      max_members: plan_member_limit(@team_params[:plan])
    )
  end

  def assign_admin(team)
    # User is already invited type, just update their team assignment
    @admin_user.update!(
      team: team,
      team_role: "admin"
    )
  end

  def setup_billing(team)
    # Create Stripe customer for team
    customer = team.set_payment_processor(:stripe)

    # Start trial if applicable
    if team.starter?
      team.update!(trial_ends_at: 14.days.from_now)
    end
  end

  def send_notifications(team)
    # TeamMailer.admin_assigned(team, @admin_user).deliver_later
  end

  def plan_member_limit(plan)
    case plan
    when "starter" then 5
    when "pro" then 15
    when "enterprise" then 100
    else 5
    end
  end

  def success(team)
    OpenStruct.new(success?: true, team: team)
  end

  def failure(message)
    OpenStruct.new(success?: false, error: message)
  end
end
