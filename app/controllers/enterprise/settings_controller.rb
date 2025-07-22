# Enterprise::SettingsController
#
# Manages enterprise organization settings and configuration within the triple-track SaaS system.
# Handles organization-wide settings that affect all enterprise members, including branding,
# contact information, and operational parameters specific to enterprise groups.
#
# **Access Control:**
# - RESTRICTED to Enterprise Admins only (enterprise_group_role: 'admin')
# - Enterprise Members cannot access or modify settings
# - Inherits enterprise user validation from Enterprise::BaseController
# - Critical for maintaining enterprise group configuration security
#
# **Settings Management vs Other Systems:**
# - Enterprise settings are isolated from direct user preferences (/dashboard/settings)
# - Different from team settings (/teams/:slug/admin/settings)
# - Organization-wide settings affect all enterprise group members
# - Enterprise-specific configuration options and branding controls
#
# **Enterprise Settings Categories:**
# - Organization Information: name, contact details, description
# - Member Management: max_members, invitation policies, role permissions
# - Branding & Theme: logo, colors, custom styling (enterprise purple theme)
# - Billing Configuration: billing address, tax settings, payment preferences
# - Security Settings: access controls, authentication requirements
# - Feature Toggles: enterprise-specific feature availability
#
# **Settings vs Configuration:**
# - Settings: Admin-modifiable organization preferences
# - Configuration: System-level settings managed by Super Admins
# - Enterprise groups cannot modify system-wide configuration
# - Settings changes affect current enterprise group only
#
# **Business Logic:**
# - Settings changes are audited for compliance tracking
# - Some settings may require system validation before activation
# - Settings affect all current and future enterprise members
# - Certain settings may impact billing or feature availability
#
# **URL Structure:**
# All routes scoped under /enterprise/:enterprise_group_slug/settings/
# - Multi-tenant settings management via enterprise group slug
# - Settings isolated to specific enterprise organization
class Enterprise::SettingsController < Enterprise::BaseController
  # Restrict all settings access to enterprise admins only
  before_action :require_admin!
  
  # Skip Pundit policy verification (handled by admin check)
  skip_after_action :verify_policy_scoped, only: [ :show ]
  skip_after_action :verify_authorized, only: [ :show, :update ]

  # Displays enterprise group settings management interface
  #
  # **Settings Categories Displayed:**
  # - Organization Information: name, contact details, description
  # - Member Management: maximum members, invitation policies
  # - Billing Settings: billing address, payment preferences
  # - Security Configuration: access controls, authentication settings
  # - Feature Management: enabled/disabled enterprise features
  #
  # **Access:**
  # - Enterprise Admins only (enforced by require_admin!)
  # - Settings are organization-wide and affect all members
  # - Form displays current values with update capabilities
  #
  # **UI Features:**
  # - Enterprise-themed settings interface (purple branding)
  # - Organized settings sections with clear categorization
  # - Help text and validation guidance for each setting
  # - Preview capabilities for branding and theme changes
  def show
    # Settings page displays current enterprise group configuration
  end

  # Updates enterprise group settings with validation
  #
  # **Update Process:**
  # 1. Validates all settings according to enterprise requirements
  # 2. Checks business rules (e.g., max_members against current count)
  # 3. Updates settings with audit trail logging
  # 4. Applies changes immediately across enterprise group
  #
  # **Validation Logic:**
  # - Name: Required, unique within system, professional standards
  # - Contact Details: Valid email/phone formats, business verification
  # - Billing Address: Required for enterprise billing, format validation
  # - Max Members: Must be >= current member count, within plan limits
  #
  # **Business Rules:**
  # - Cannot reduce max_members below current member count
  # - Name changes may affect URL slugs and integrations
  # - Contact email must be verified for billing purposes
  # - Settings changes are logged for audit compliance
  #
  # **Error Handling:**
  # - Validation errors displayed with specific field guidance
  # - Business rule violations explained with corrective actions
  # - Partial updates prevented (all-or-nothing approach)
  def update
    if @enterprise_group.update(settings_params)
      redirect_to settings_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Settings updated successfully"
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  # Restricts access to enterprise administrators only
  #
  # **Authorization Logic:**
  # - Checks current_user.enterprise_admin? method
  # - Enterprise members are blocked from settings access
  # - Settings are organization-wide and require admin privileges
  # - Prevents unauthorized configuration changes
  #
  # **Security Rationale:**
  # - Settings affect all enterprise members
  # - Billing and security settings require admin oversight
  # - Member role separation maintains operational security
  #
  # **Redirects:**
  # - Non-admin enterprise users → enterprise dashboard with error message
  def require_admin!
    unless current_user.enterprise_admin?
      redirect_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "You don't have permission to access settings"
    end
  end

  # Strong parameters for enterprise group settings updates
  #
  # **Permitted Settings:**
  # - name: Organization name (affects branding and identification)
  # - contact_email: Primary contact for billing and communications
  # - contact_phone: Business contact number for support and verification
  # - billing_address: Required for enterprise billing and tax purposes
  # - max_members: Maximum allowed members (within plan constraints)
  #
  # **Security Notes:**
  # - Sensitive settings like API keys handled separately
  # - Billing-related changes may trigger external validations
  # - Some settings may require additional confirmation steps
  def settings_params
    params.require(:enterprise_group).permit(:name, :contact_email, :contact_phone,
                                            :billing_address, :max_members)
  end
end
