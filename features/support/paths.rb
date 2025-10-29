module NavigationHelpers
  def path_for(page_name)
    case page_name.downcase
    when 'home', 'login'
      root_path
    when 'calendar'
      calendar_path
    when 'dashboard'
      dashboard_path
    when 'statistics'
      statistics_path
    when 'the leetCode page', 'leetcode'
      leetcode_path
    when 'the profile page', 'profile'
      profile_path
    when 'sign out', 'logout'
      logout_path
    else
      raise "Can't find mapping from \"#{page_name}\" to a path."
    end
  end
end

World(NavigationHelpers)
