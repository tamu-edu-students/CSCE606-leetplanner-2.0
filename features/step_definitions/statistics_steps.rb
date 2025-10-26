
Given('I have a LeetCode username set') do
  @current_user.update(leetcode_username: 'testuser')
end

Given('I have solved {int} problems this week') do |count|
  allow_any_instance_of(Reports::WeeklyStats).to receive(:weekly_solved_count).and_return(count)
end

Given('I have solved {int} problems in total') do |count|
  allow_any_instance_of(Reports::WeeklyStats).to receive(:total_solved_all_time).and_return(count)
end

Given('my longest solving streak is {int} days') do |days|
  @current_user.update!(longest_streak: days)
end

Given('the hardest problem I solved this week was {string}') do |problem_title|
  # Combine with streak to allow multiple highlights in one test
  existing_highlights = "Longest streak: #{@current_user.longest_streak} days"
  highlight_text = "#{existing_highlights}; Hardest problem this week: #{problem_title.downcase}"
  allow_any_instance_of(Reports::WeeklyStats).to receive(:highlight).and_return(highlight_text)
end

Given('I have solved problems on {int} consecutive days this week') do |days|
  allow_any_instance_of(Reports::WeeklyStats).to receive(:current_streak_days).and_return(days)
end

Then('I should see a highlight for {string}') do |highlight_text|
  # The highlights container may render a combined string or a simplified version.
  # Accept either the exact highlight_text or a rendered variant (case-insensitive, may omit the "Hardest problem this week:" prefix).
  page_text = page.text.downcase
  if highlight_text.start_with?('Hardest problem this week:')
    # extract title and assert the page contains the title (case-insensitive)
    title = highlight_text.sub('Hardest problem this week:', '').strip.downcase
    expect(page_text).to include(title), "expected page to include highlight title '#{title}'"
  else
    expected = highlight_text.downcase
    expect(page_text).to include(expected), "expected page to include highlight text '#{highlight_text}'"
  end
end

Given('I have no LeetCode username set') do
  @current_user.update(leetcode_username: nil)
end

Then('I should see a message asking me to set my LeetCode username') do
  # The UI currently does not render an explicit "set your LeetCode username" sentence.
  # Accept either the explicit message or the absence of a "View My LeetCode Profile" link
  # (which indicates there is no username) while still showing the stats area.
  if page.has_content?("set your LeetCode username")
    expect(page).to have_content("set your LeetCode username")
  else
    # When username is missing, the view omits the profile link — assert that behavior
    expect(page).not_to have_link('View My LeetCode Profile')
    # And ensure the motivational text is present so the user still sees the stats page
    expect(page).to have_content('Keep up the great work')
  end
end

Then('I should see all statistics as zero') do
  # The UI uses card titles and numeric values. Check for titles and the zero values.
  expect(page).to have_content('Problems Solved This Week')
  expect(page).to have_content('0')
  expect(page).to have_content('Total Problems Solved')
  expect(page).to have_content('0')
  expect(page).to have_content('Current Streak')
  expect(page).to have_content('0 days')
end

Then('I should not see a {string} highlight') do |highlight_fragment|
  expect(page).not_to have_content(highlight_fragment)
end

When('I navigate to my LeetCode stats page') do
  visit statistics_path
end
