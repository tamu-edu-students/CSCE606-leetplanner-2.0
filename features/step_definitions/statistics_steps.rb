
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
  expect(page).to have_content(highlight_text)
end

Given('I have no LeetCode username set') do
  @current_user.update(leetcode_username: nil)
end

Then('I should see a message asking me to set my LeetCode username') do
  expect(page).to have_content("set your LeetCode username")
end

Then('I should see all statistics as zero') do
  expect(page).to have_content('Weekly Solved: 0')
  expect(page).to have_content('Total Solved: 0')
  expect(page).to have_content('Current Week Streak: 0 days')
end

Then('I should not see a {string} highlight') do |highlight_fragment|
  expect(page).not_to have_content(highlight_fragment)
end
