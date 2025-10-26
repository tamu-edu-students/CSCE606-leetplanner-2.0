# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe Leetcode::FetchStats do
  let(:service) { described_class.new }
  let(:username) { 'testuser' }

  describe '#solved' do
    context 'with successful API response' do
      let(:api_response) do
        {
          'solvedProblem' => 150,
          'easySolved' => 80,
          'mediumSolved' => 50,
          'hardSolved' => 20
        }
      end

      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/#{username}/solved")
          .to_return(status: 200, body: api_response.to_json)
      end

      it 'returns parsed solved stats' do
        result = service.solved(username)
        expect(result).to eq(total: 150, easy: 80, medium: 50, hard: 20)
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/#{username}/solved")
          .to_return(status: 404)
      end

      it 'raises an error' do
        expect { service.solved(username) }.to raise_error(RuntimeError, 'HTTP 404')
      end
    end

    context 'with invalid JSON response' do
      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/#{username}/solved")
          .to_return(status: 200, body: "invalid-json")
      end

      it 'logs the JSON parse error and raises "Invalid JSON response"' do
        expect(Rails.logger).to receive(:error)
                                  .with(a_string_matching(/\[LeetCodeAPI\] JSON parse error for .*solved: /))

        expect { service.solved(username) }
          .to raise_error(RuntimeError, "Invalid JSON response")
      end
    end

    context 'with timeout' do
      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/#{username}/solved")
          .to_timeout
      end

      it 'raises an error' do
        expect { service.solved(username) }.to raise_error(Net::OpenTimeout)
      end
    end

    describe '#profile' do
      let(:api_response) { { 'username' => username, 'ranking' => 1234, 'acceptanceRate' => 65.5 } }

      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/userProfile/#{username}")
          .to_return(status: 200, body: api_response.to_json)
      end

      it 'returns profile data' do
        result = service.profile(username)
        expect(result).to eq(api_response)
      end
    end

    describe '#accepted_submissions' do
      let(:api_response) do
        {
          'submission' => [
            { 'title' => 'Two Sum', 'time' => 1234567890 }
          ]
        }
      end

      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/#{username}/acSubmission?limit=5")
          .to_return(status: 200, body: api_response.to_json)
      end

      it 'returns accepted submissions' do
        result = service.accepted_submissions(username, limit: 5)
        expect(result).to eq([ { 'title' => 'Two Sum', 'time' => 1234567890 } ])
      end
    end

    describe '#contest' do
      let(:api_response) { { 'contestAttend' => 10, 'contestRating' => 1800 } }

      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/#{username}/contest")
          .to_return(status: 200, body: api_response.to_json)
      end

      it 'returns contest data' do
        result = service.contest(username)
        expect(result).to eq(api_response)
      end
    end

    describe '#language_stats' do
      let(:api_response) { { 'data' => [ { 'languageName' => 'Python', 'problemsSolved' => 50 } ] } }

      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/languageStats?username=#{username}")
          .to_return(status: 200, body: api_response.to_json)
      end

      it 'returns language stats' do
        result = service.language_stats(username)
        expect(result).to eq(api_response)
      end
    end

    describe '#skill_stats' do
      let(:api_response) { { 'data' => [ { 'tagName' => 'Array', 'problemsSolved' => 30 } ] } }

      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/skillStats/#{username}")
          .to_return(status: 200, body: api_response.to_json)
      end

      it 'returns skill stats' do
        result = service.skill_stats(username)
        expect(result).to eq(api_response)
      end
    end

    describe '#calendar' do
      let(:api_response) { { 'submissionCalendar' => '{"1735689600":5,"1735776000":3}' } }

      before do
        stub_request(:get, "https://alfa-leetcode-api.onrender.com/#{username}/calendar")
          .to_return(status: 200, body: api_response.to_json)
      end

      it 'returns calendar data with parsed submissionCalendar' do
        result = service.calendar(username)
        expect(result['submissionCalendar']).to eq({ '1735689600' => 5, '1735776000' => 3 })
      end
    end
  end
end
