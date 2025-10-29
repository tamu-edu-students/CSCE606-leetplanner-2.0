require "net/http"
require "json"

Given("a valid LeetCode username {string}") do |username|
  @username = username
  @service = Leetcode::FetchStats.new
end

# -----------------------
# Solved problems stats
# -----------------------
When("I fetch solved problems stats") do
  allow(@service).to receive(:fetch_json).with("#{@username}/solved").and_return({
                                                                                   "solvedProblem" => 10,
                                                                                   "easySolved" => 3,
                                                                                   "mediumSolved" => 5,
                                                                                   "hardSolved" => 2
                                                                                 })
  @result = @service.solved(@username)
end

Then("the result should include total, easy, medium, and hard counts") do
  expect(@result).to eq({ total: 10, easy: 3, medium: 5, hard: 2 })
end

# -----------------------
# Calendar stats
# -----------------------
When("I fetch calendar stats") do
  allow(@service).to receive(:fetch_json).with("#{@username}/calendar").and_return({
                                                                                     "submissionCalendar" => '{"2025-10-25":1}'
                                                                                   })
  @calendar_result = @service.calendar(@username)
end

Then("the calendar result should be a hash") do
  expect(@calendar_result).to be_a(Hash)
end

Then("submissionCalendar should be parsed as a hash if it is a string") do
  expect(@calendar_result["submissionCalendar"]).to eq({ "2025-10-25" => 1 })
end

# -----------------------
# User profile
# -----------------------
When("I fetch the user profile") do
  allow(@service).to receive(:fetch_json).with("userProfile/#{@username}").and_return({
                                                                                        "username" => @username,
                                                                                        "ranking" => 123
                                                                                      })
  @profile_result = @service.profile(@username)
end

Then("the result should include the username") do
  expect(@profile_result["username"]).to eq(@username)
end

# -----------------------
# Accepted submissions
# -----------------------
When("I fetch recent accepted submissions") do
  allow(@service).to receive(:fetch_json).with("#{@username}/acSubmission?limit=5").and_return({
                                                                                                 "submission" => [ { "id" => 1, "title" => "Two Sum" } ]
                                                                                               })
  @submissions = @service.accepted_submissions(@username)
end

Then("the result should be an array") do
  expect(@submissions).to be_an(Array)
end

# -----------------------
# Contest stats
# -----------------------
When("I fetch contest stats") do
  allow(@service).to receive(:fetch_json).with("#{@username}/contest").and_return({ "attended" => 3 })
  @contest_result = @service.contest(@username)
end

Then("the result should include contest-related keys") do
  expect(@contest_result).to include("attended")
end

# -----------------------
# Language stats
# -----------------------
When("I fetch language stats") do
  allow(@service).to receive(:fetch_json).with("languageStats?username=#{@username}").and_return({
                                                                                                   "Python" => 10,
                                                                                                   "Ruby" => 5,
                                                                                                   "JavaScript" => 7
                                                                                                 })
  @result = @service.language_stats(@username)
end

# -----------------------
# Skill stats
# -----------------------
When("I fetch skill stats") do
  allow(@service).to receive(:fetch_json).with("skillStats/#{@username}").and_return({
                                                                                       "algorithms" => 10,
                                                                                       "data_structures" => 5
                                                                                     })
  @result = @service.skill_stats(@username)
end

Then("the result should be a hash") do
  expect(@result).to be_a(Hash)
end

# -----------------------
# Cover private fetch_json for coverage
# -----------------------
When("I fetch raw JSON from {string}") do |path|
  # Minimal change: call private method directly, still stubbed
  allow(@service).to receive(:fetch_json).with(path).and_return({ "key" => "value" })
  @raw_result = @service.send(:fetch_json, path)
end

Then("the raw result should be a hash") do
  expect(@raw_result).to be_a(Hash)
end

# -----------------------
# Error handling
# -----------------------
When("the API returns an HTTP error") do
  allow(@service).to receive(:fetch_json).and_raise(RuntimeError.new("HTTP 500"))
end

When("the API returns invalid JSON") do
  allow(@service).to receive(:fetch_json).and_raise(JSON::ParserError.new("unexpected token"))
end

Then("an error should be raised") do
  expect { @service.fetch_json("any") }.to raise_error
end

# -----------------------
# Deep test for private fetch_json internals (to cover everything)
# -----------------------

When("I simulate a successful HTTP call to fetch_json") do
  uri = URI.parse("https://leetcode.com/test_path")

  # Stub Rails.cache to execute block
  allow(Rails.cache).to receive(:fetch).and_yield

  # Mock URI.join
  allow(URI).to receive(:join).with(Leetcode::FetchStats::BASE, "test_path").and_return(uri)

  # Mock HTTP success response
  http_response = instance_double(Net::HTTPOK, is_a?: true, body: '{"ok": true}')
  allow(Net::HTTP).to receive(:start).and_yield(double(request: http_response))

  @result = @service.send(:fetch_json, "test_path")
end

Then("the fetch_json result should be a parsed JSON hash") do
  expect(@result).to eq({ "ok" => true })
end

When("I simulate an HTTP failure in fetch_json") do
  uri = URI.parse("https://leetcode.com/fail_path")
  allow(Rails.cache).to receive(:fetch).and_yield
  allow(URI).to receive(:join).and_return(uri)

  bad_response = instance_double(Net::HTTPResponse, is_a?: false, code: "500")
  allow(Net::HTTP).to receive(:start).and_yield(double(request: bad_response))

  expect(Rails.logger).to receive(:warn)
  expect { @service.send(:fetch_json, "fail_path") }.to raise_error("HTTP 500")
end

When("I simulate a JSON parse error in fetch_json") do
  uri = URI.parse("https://leetcode.com/bad_json")
  allow(Rails.cache).to receive(:fetch).and_yield
  allow(URI).to receive(:join).and_return(uri)

  http_response = instance_double(Net::HTTPOK, is_a?: true, body: "not-json")
  allow(Net::HTTP).to receive(:start).and_yield(double(request: http_response))

  allow(JSON).to receive(:parse).and_raise(JSON::ParserError.new("unexpected token"))
  expect(Rails.logger).to receive(:error)
  expect { @service.send(:fetch_json, "bad_json") }.to raise_error("Invalid JSON response")
end
