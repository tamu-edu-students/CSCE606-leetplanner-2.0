Given('I have completed the following LeetCode sessions this week:') do |table|
  table.hashes.each do |session|
    create(:leet_code_session,
           user: @current_user,
           problem_title: session['problem_title'],
           duration_minutes: session['duration'].to_i,
           difficulty: session['difficulty'],
           completed_at: Time.current)
  end
end

Given('I have no LeetCode sessions this week') do
  LeetCodeSession.where(user: @current_user).destroy_all
end

Given('I have completed LeetCode sessions:') do |table|
  table.hashes.each do |session|
    create(:leet_code_session,
           user: @current_user,
           completed_at: Date.parse(session['date']).to_time,
           problem_count: session['problems_solved'].to_i)
  end
end

Then('I should see my total study time as {string}') do |time|
  expect(page).to have_content("Total Study Time: #{time}")
end

Then('I should see {string} problems solved this week') do |count|
  expect(page).to have_content("Problems Solved This Week: #{count}")
end

Then('I should see a streak count') do
  expect(page).to have_css('.streak-count')
end

Then('my streak should be {string}') do |streak|
  expect(page).to have_content("Current Streak: #{streak}")
end

Then('I should see a {string} streak') do |streak|
  expect(page).to have_content("Current Streak: #{streak}")
end

Then('I should see these sessions in my history') do
  expect(page).to have_css('.session-history')
  @current_user.leet_code_sessions.each do |session|
    expect(page).to have_content(session.completed_at.strftime('%Y-%m-%d'))
    expect(page).to have_content(session.problem_count.to_s)
  end
end