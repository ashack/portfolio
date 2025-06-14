class Admin::Super::EmailChangeRequestsController < Admin::Super::BaseController
  include Pundit::Authorization
  before_action :set_email_change_request, only: [ :show, :approve, :reject ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @email_change_requests = policy_scope(EmailChangeRequest).includes(:user, :approved_by)
                                                            .recent
    @pagy, @email_change_requests = pagy(@email_change_requests)
  end

  def show
    authorize @email_change_request, :show?
  end

  def approve
    authorize @email_change_request, :approve?

    if @email_change_request.approve!(current_user, notes: params[:notes])
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  notice: "Email change request approved successfully."
    else
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  alert: "Failed to approve email change request: #{@email_change_request.errors.full_messages.join(', ')}"
    end
  end

  def reject
    authorize @email_change_request, :reject?

    if params[:notes].blank?
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  alert: "Rejection reason is required."
      return
    end

    if @email_change_request.reject!(current_user, notes: params[:notes])
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  notice: "Email change request rejected."
    else
      redirect_to admin_super_email_change_request_path(@email_change_request),
                  alert: "Failed to reject email change request: #{@email_change_request.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_email_change_request
    @email_change_request = EmailChangeRequest.find_by!(token: params[:token])
  end
end
