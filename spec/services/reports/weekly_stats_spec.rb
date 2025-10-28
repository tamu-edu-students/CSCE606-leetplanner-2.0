require "rails_helper"

RSpec.describe Reports::WeeklyStats do
  # Use let! for user to ensure it's created before tests
  let!(:user) { User.create!(netid: "test_user", email: "test@example.com", first_name: "Test", last_name: "User", active: true) }
  let(:week_start) { Time.zone.parse("2025-10-26 00:00:00") } # A Sunday
  let(:service) { described_class.new(user, week_start: week_start) }
  let!(:session) { LeetCodeSession.create!(user: user, scheduled_time: Time.zone.now, duration_minutes: 60) }

  # Helper to create a solved problem on a specific date
  def create_solved_problem(date)
    problem = LeetCodeProblem.create!(
      leetcode_id: SecureRandom.hex(4),
      title: "Problem on #{date}",
      difficulty: "Easy"
    )
    LeetCodeSessionProblem.create!(
      leet_code_session: session,
      leet_code_problem: problem,
      solved: true,
      solved_at: date
    )
  end

  describe "#call" do
    context "with no solved problems" do
      it "returns zero stats" do
        result = service.call
        expect(result[:weekly_solved_count]).to eq(0)
        expect(result[:current_streak_days]).to eq(0)
        expect(result[:total_solved_all_time]).to eq(0)
        expect(result[:highlight]).to eq("")
      end
    end

    context "with a single solved problem" do
      let!(:problem) { LeetCodeProblem.create!(leetcode_id: "1", title: "Test Problem", difficulty: "Hard") }
      let!(:solved_problem) do
        create_solved_problem(week_start + 1.day) # Monday
      end

      it "counts the weekly solved problem" do
        result = service.call
        expect(result[:weekly_solved_count]).to eq(1)
      end

      it "calculates a single-day streak" do
        result = service.call
        expect(result[:current_streak_days]).to eq(1)
      end

      it "includes the hardest problem in the highlight" do
        result = service.call
        # We need to find the problem created by the helper
        hardest = LeetCodeProblem.find_by(title: "Problem on #{week_start + 1.day}")
        expect(result[:highlight]).to include("Hardest problem this week: #{hardest.title} (easy)")
      end

      it "includes the longest historical streak in the highlight" do
        user.update(longest_streak: 5)
        result = service.call
        expect(result[:highlight]).to include("Longest streak: 5 days")
      end
    end

    context "with various weekly streaks" do
      it "calculates a consecutive two-day streak" do
        create_solved_problem(week_start + 1.day) # Monday
        create_solved_problem(week_start + 2.days) # Tuesday
        
        result = service.call
        expect(result[:current_streak_days]).to eq(2)
      end

      it "handles a broken streak" do
        create_solved_problem(week_start + 1.day) # Monday
        create_solved_problem(week_start + 3.days) # Wednesday (skips Tuesday)
        
        result = service.call
        # The longest streak is 1 day, either Monday or Wednesday
        expect(result[:current_streak_days]).to eq(1)
      end

      it "finds the max streak when there are multiple streaks" do
        create_solved_problem(week_start + 1.day)  # Monday
        create_solved_problem(week_start + 2.days)  # Tuesday (Streak of 2)
        create_solved_problem(week_start + 4.days)  # Thursday (Streak of 1)
        
        result = service.call
        expect(result[:current_streak_days]).to eq(2)
      end
    end

    context "with problems outside the week" do
      it "does not count problems outside the week for weekly stats but does for total" do
        create_solved_problem(week_start - 1.day) # Saturday before
        
        result = service.call
        expect(result[:weekly_solved_count]).to eq(0)
        expect(result[:total_solved_all_time]).to eq(1)
      end
    end
  end
end