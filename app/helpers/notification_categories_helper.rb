module NotificationCategoriesHelper
  def category_scope_badge(category)
    case category.scope
    when 'system'
      content_tag(:span, 'System', class: 'ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800')
    when 'team'
      content_tag(:span, 'Team', class: 'ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800')
    when 'enterprise'
      content_tag(:span, 'Enterprise', class: 'ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-purple-100 text-purple-800')
    end
  end
  
  def category_status_badge(category)
    if category.active?
      content_tag(:span, 'Active', class: 'ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800')
    else
      content_tag(:span, 'Inactive', class: 'ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-red-100 text-red-800')
    end
  end
  
  def can_edit_category?(category, current_user)
    case category.scope
    when 'system'
      current_user.super_admin?
    when 'team'
      current_user.super_admin? || 
        (current_user.team_id == category.team_id && current_user.team_admin?)
    when 'enterprise'
      current_user.super_admin? || 
        (current_user.enterprise_group_id == category.enterprise_group_id && current_user.enterprise_group_role == 'admin')
    else
      false
    end
  end
  
  def category_owner_info(category)
    case category.scope
    when 'team'
      "#{category.team.name}" if category.team
    when 'enterprise'
      "#{category.enterprise_group.name}" if category.enterprise_group
    else
      "Platform-wide"
    end
  end
end