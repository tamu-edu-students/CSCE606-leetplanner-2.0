Feature: Fetch LeetCode user statistics
  The Leetcode::FetchStats service fetches various stats for a user

  Background:
    Given a valid LeetCode username "test_user"

  Scenario: Fetch solved problems stats
    When I fetch solved problems stats
    Then the result should include total, easy, medium, and hard counts

  Scenario: Fetch calendar stats
    When I fetch calendar stats
    Then the calendar result should be a hash
    And submissionCalendar should be parsed as a hash if it is a string

  Scenario: Fetch user profile
    When I fetch the user profile
    Then the result should include the username

  Scenario: Fetch accepted submissions
    When I fetch recent accepted submissions
    Then the result should be an array

  Scenario: Fetch contest stats
    When I fetch contest stats
    Then the result should include contest-related keys

  Scenario: Fetch language stats
    When I fetch language stats
    Then the result should be a hash

  Scenario: Fetch skill stats
    When I fetch skill stats
    Then the result should be a hash

  Scenario: Fetch raw JSON from private method
    When I fetch raw JSON from "some/path"
    Then the raw result should be a hash

  Scenario: API returns HTTP error
    When the API returns an HTTP error
    Then an error should be raised

  Scenario: API returns invalid JSON
    When the API returns invalid JSON
    Then an error should be raised

  Scenario: Successful internal HTTP call for fetch_json
    When I simulate a successful HTTP call to fetch_json
    Then the fetch_json result should be a parsed JSON hash

  Scenario: HTTP failure in fetch_json
    When I simulate an HTTP failure in fetch_json
    Then an error should be raised

  Scenario: JSON parse error in fetch_json
    When I simulate a JSON parse error in fetch_json
    Then an error should be raised
