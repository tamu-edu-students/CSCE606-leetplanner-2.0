source "https://rubygems.org"

# --- Rails Framework ---
gem "rails", "~> 8.0.2"

# --- Assets & JavaScript ---
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "dartsass-rails"

# --- Database & Server ---
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# --- API & Services ---
gem "jbuilder"
gem "google-api-client", "~> 0.53.0"
gem "httparty"
gem "nokogiri"

# --- Authentication ---
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-google-oauth2"

# --- Caching & Background Jobs ---
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# --- Utilities & Deployment ---
gem "kaminari"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false

# Gems used only for development and testing
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "dotenv-rails"
  gem "rspec-rails"
  gem "shoulda-matchers"
  gem "webmock", "~> 3.25"
  gem "vcr", "~> 6.3"
  gem "rack_session_access"
  gem "rack-cors"
  gem "faker"
  gem "activerecord-session_store"
end

# Gems used only for development
group :development do
  gem "web-console"
  gem "foreman"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

# Gems used only for testing
group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "cucumber-rails", require: false
  gem "database_cleaner-active_record"
  gem "factory_bot_rails"
  gem "timecop"
  gem "launchy"
  gem "rails-controller-testing"
  gem "simplecov", require: false
  gem "devise"
end
