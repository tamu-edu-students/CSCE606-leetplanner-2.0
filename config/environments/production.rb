require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.public_file_server.enabled = true

  # Store uploaded files on the local file system (Heroku FS is ephemeral; for persistence use cloud storage).
  config.active_storage.service = :local

  config.assume_ssl = true
  config.force_ssl  = true

  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  config.cache_store = :memory_store

  config.active_job.queue_adapter = :inline

  # Mailer
  config.action_mailer.default_url_options = {
    host: "leetplanner-staging-9448a75c94bd.herokuapp.com"
  }
  config.action_mailer.smtp_settings = {
    user_name: ENV["MAILGUN_SMTP_LOGIN"],
    password:  ENV["MAILGUN_SMTP_PASSWORD"],
    address:   "smtp.mailgun.org",
    port:      587,
    authentication: :plain,
    enable_starttls_auto: true
  }

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
end
