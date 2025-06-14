class Teams::Admin::EmailChangeRequestsController < Teams::Admin::BaseController
  include Pundit::Authorization
  before_action :set_email_change_request, only: [ :show, :approve, :reject ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    # Team admins can only see requests from their team members
    @email_change_requests = policy_scope(EmailChangeRequest).includes(:user, :approved_by)
                                                            .recent
    @pagy, @email_change_requests = pagy(@email_change_requests)
  end

  def show
    authorize @email_change_request, :show?
  end

  def new
    @email_change_request = EmailChangeRequest.new
    authorize @email_change_request, :create?
  end

  def create
    @email_change_request = EmailChangeRequest.new(email_change_request_params)
    @email_change_request.user = current_user
    authorize @email_change_request, :create?

    if @email_change_request.save
      redirect_to team_admin_email_change_requests_path(@team),
                  notice: "Email change request submitted successfully. You will be notified when it's reviewed."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    authorize @email_change_request, :approve?

    if @email_change_request.approve!(current_user, notes: params[:notes])
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  notice: "Email change request approved successfully."
    else
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  alert: "Failed to approve email change request: #{@email_change_request.errors.full_messages.join(', ')}"
    end
  end

  def reject
    authorize @email_change_request, :reject?

    if params[:notes].blank?
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  alert: "Rejection reason is required."
      return
    end

    if @email_change_request.reject!(current_user, notes: params[:notes])
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  notice: "Email change request rejected."
    else
      redirect_to team_admin_email_change_request_path(@team, @email_change_request),
                  alert: "Failed to reject email change request: #{@email_change_request.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_email_change_request
    @email_change_request = EmailChangeRequest.joins(:user)
                                             .where(users: { team_id: current_user.team_id })
                                             .find_by!(token: params[:token])
  end

  def email_change_request_params
    params.require(:email_change_request).permit(:new_email, :reason)
  end
end
