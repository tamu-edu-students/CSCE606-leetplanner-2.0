# Helper to create a solved LeetCode problem on a specific date for the current user
def create_solved_problem(date, title, difficulty)
  session = LeetCodeSession.create!(user: @current_user, scheduled_time: date, duration_minutes: 30)
  problem = LeetCodeProblem.create!(leetcode_id: SecureRandom.hex(4), title: title, difficulty: difficulty)
  LeetCodeSessionProblem.create!(
    leet_code_session: session,
    leet_code_problem: problem,
    solved: true,
    solved_at: date
  )
end

# --- Step Definitions for Streak Scenarios ---

Given('I solved a problem on Monday of this week') do
  # Travel to a Wednesday to ensure Monday/Tuesday are in the past
  travel_to Time.zone.now.beginning_of_week(:sunday).advance(days: 3) do
    monday = Time.zone.now.beginning_of_week(:sunday).advance(days: 1)
    create_solved_problem(monday, "Monday Problem", "Easy")
  end
end

Given('I solved a problem on Tuesday of this week') do
  tuesday = Time.zone.now.beginning_of_week(:sunday).advance(days: 2)
  create_solved_problem(tuesday, "Tuesday Problem", "Easy")
end

Given('I solved a problem on Wednesday of this week') do
  wednesday = Time.zone.now.beginning_of_week(:sunday).advance(days: 3)
  create_solved_problem(wednesday, "Wednesday Problem", "Easy")
end

When('I visit the statistics page') do
  visit statistics_path # Assumes a route helper named statistics_path
end

Then('I should see a "Current Week Streak" of {string}') do |streak_text|
  expect(page).to have_content("Current Streak")
  expect(page).to have_content(streak_text)
end

# --- Step Definitions for Highlight Scenarios ---

Given(/I solved (?:a|an) "([^"]*)" problem titled "([^"]*)" this week/) do |difficulty, title|
  date = Time.zone.now.beginning_of_week(:sunday).advance(days: 1)
  create_solved_problem(date, title, difficulty)
end

Given('my historical longest streak is {int} days') do |streak_days|
  @current_user.update!(longest_streak: streak_days)
end

Then('I should see the highlight {string}') do |highlight_text|
  expect(page).to have_content(highlight_text)
end
