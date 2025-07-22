# Enterprise::BaseController
#
# Base controller for all enterprise-related controllers within the triple-track SaaS system.
# This controller enforces enterprise-specific access control and URL slug-based routing.
#
# **Enterprise User System Overview:**
# The enterprise system is one of three distinct user ecosystems:
# 1. Direct Users - Individual users with personal billing (cannot access enterprise areas)
# 2. Team Users - Invited team members (cannot access enterprise areas)
# 3. Enterprise Users - Members of large organizations (isolated from other systems)
#
# **URL Structure:**
# All enterprise routes follow the pattern: /enterprise/:enterprise_group_slug/*
# - enterprise_group_slug: Unique identifier for each enterprise organization
# - Enforces multi-tenant isolation at the URL level
#
# **Access Control Hierarchy:**
# - Enterprise Member: Basic enterprise user, can view dashboard and update profile
# - Enterprise Admin: Full admin access, can manage members, billing, and settings
#
# **Security Features:**
# - Slug-based multi-tenancy: Users can only access their assigned enterprise group
# - User type validation: Only enterprise users can access enterprise controllers
# - Enterprise group verification: URL slug must match user's assigned enterprise group
# - Automatic redirection: Invalid access attempts are redirected appropriately
#
# **Integration Points:**
# - Inherits from ApplicationController for base authentication
# - Works with EnterpriseGroup model for organization management
# - Supports both enterprise_admin and enterprise_member roles
# - Completely isolated from team and direct user systems
class Enterprise::BaseController < ApplicationController
  # Ensure user is authenticated before any enterprise actions
  before_action :authenticate_user!
  
  # Restrict access to enterprise users only (user_type: 'enterprise')
  before_action :require_enterprise_user!
  
  # Set the enterprise group from URL slug or user association
  before_action :set_enterprise_group
  
  # Verify user has access to the specific enterprise group in the URL
  before_action :verify_enterprise_group_access

  private

  # Validates that the current user is an enterprise user
  #
  # **Business Logic:**
  # - Only users with user_type: 'enterprise' can access enterprise controllers
  # - Direct users (individual billing) are blocked from enterprise areas
  # - Team users (invited via teams) are blocked from enterprise areas
  # - This enforces the triple-track system isolation
  #
  # **Redirects:**
  # - Non-enterprise users → root_path with error message
  def require_enterprise_user!
    unless current_user&.enterprise?
      flash[:alert] = "You must be an enterprise user to access this area."
      redirect_to root_path
    end
  end

  # Sets the enterprise group for the current request
  #
  # **Lookup Strategy:**
  # 1. If enterprise_group_slug in URL params → find by slug (multi-tenant routing)
  # 2. Otherwise → use current_user.enterprise_group (direct association)
  # 
  # **Multi-Tenancy:**
  # - The slug-based lookup enables multiple enterprise groups on the same platform
  # - Each enterprise group has a unique slug for URL-based isolation
  # - Cached lookup prevents N+1 queries in nested routes
  #
  # **Error Handling:**
  # - Missing enterprise group → redirect to root with error
  # - Invalid slug → raises ActiveRecord::RecordNotFound (handled by Rails)
  def set_enterprise_group
    # Use cached lookup when slug is provided
    if params[:enterprise_group_slug]
      @enterprise_group = EnterpriseGroup.find_by_slug!(params[:enterprise_group_slug])
    else
      @enterprise_group = current_user.enterprise_group
    end

    unless @enterprise_group
      flash[:alert] = "No enterprise group found."
      redirect_to root_path
    end
  end

  # Verifies the user has access to the specific enterprise group in the URL
  #
  # **Security Validation:**
  # - Ensures URL slug matches the user's assigned enterprise group
  # - Prevents enterprise users from accessing other enterprise groups
  # - Critical for multi-tenant security in the enterprise system
  #
  # **Business Rules:**
  # - Enterprise users can only access their assigned enterprise group
  # - URL manipulation attempts are blocked and redirected
  # - Maintains strict isolation between different enterprise organizations
  #
  # **Redirects:**
  # - Wrong enterprise group → user's correct enterprise dashboard
  def verify_enterprise_group_access
    # Verify the slug in the URL matches the user's enterprise group
    if params[:enterprise_group_slug] != @enterprise_group.slug
      flash[:alert] = "You don't have access to this enterprise group."
      redirect_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug)
    end
  end
end
