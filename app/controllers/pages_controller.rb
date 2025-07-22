# Controller for public static pages (pricing, features, legal pages)
# All pages are publicly accessible without authentication
class PagesController < ApplicationController
  # Allow public access to all pages
  skip_before_action :authenticate_user!
  # Skip authorization - these are public informational pages
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  # GET /pricing
  # Display pricing information for individual and team plans
  def pricing
    # Load active plans for display on pricing page
    @individual_plans = Plan.active.for_individuals
    @team_plans = Plan.active.for_teams
  end

  # GET /features
  # Display features and capabilities of the platform
  def features
    # Static page - no data preparation needed
  end

  # GET /choose_plan_type
  # Plan selection flow entry point
  def choose_plan_type
    # Clear any previous plan segment selection from session
    # Ensures clean state when user starts plan selection
    session.delete(:plan_segment)
  end

  # GET /contact_sales
  # Contact form for enterprise sales inquiries
  def contact_sales
    # Static contact page - form handled by external service or JavaScript
  end

  # GET /terms
  # Terms of service page - required for legal compliance
  def terms
    # Static legal page
  end

  # GET /privacy
  # Privacy policy page - required for legal compliance
  def privacy
    # Static legal page
  end
end
