# Site Admin Enterprise Groups Controller
#
# PURPOSE:
# Provides site admin interface for viewing enterprise groups in a read-only capacity.
# Site admins can view enterprise groups for customer support but cannot create or modify them.
#
# ACCESS RESTRICTIONS:
# - Site admins have READ-ONLY access to enterprise groups
# - NO create, edit, delete, or management capabilities
# - Cannot create enterprise groups (only super admins can)
# - Cannot manage enterprise members or billing
# - Inherits from Admin::Site::BaseController which enforces site_admin role
#
# BUSINESS RULES:
# - Only super admins can create enterprise groups
# - Site admins provide support for enterprise customers
# - Enterprise groups are invitation-only ecosystems
# - Each enterprise group operates independently with own billing
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# - Enterprise users are completely separate from direct and team users
# - Site admins need visibility for customer support purposes
# - No crossover between enterprise and other user types
class Admin::Site::EnterpriseGroupsController < Admin::Site::BaseController
  before_action :set_enterprise_group, only: [ :show ]

  # Display enterprise group details for site admin support purposes
  #
  # WHAT IT SHOWS:
  # - Enterprise group information and status
  # - Current members for support context
  # - Pending invitations to understand group growth
  #
  # SECURITY:
  # - Uses Pundit authorization to verify site admin can view this enterprise group
  # - Includes invitation creator info for support context
  #
  # SUPPORT USE CASES:
  # - Help enterprise customers with member questions
  # - Understand group structure for support tickets
  # - View invitation status when customers report issues
  #
  # READ-ONLY ACCESS:
  # - Site admins cannot modify enterprise groups
  # - Cannot manage members or send invitations
  # - Cannot access billing information
  def show
    authorize @enterprise_group, :show?
    @members = @enterprise_group.users
    @pending_invitations = @enterprise_group.invitations.pending.includes(:invited_by)
  end

  private

  # Find enterprise group by slug for consistent URL structure
  #
  # SECURITY: Uses find_by! to raise 404 if not found (prevents enumeration)
  # ROUTING: Enterprise groups use slugs in URLs for clean routing
  def set_enterprise_group
    @enterprise_group = EnterpriseGroup.find_by!(slug: params[:id])
  end
end
