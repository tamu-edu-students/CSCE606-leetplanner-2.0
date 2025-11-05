Rails.application.config.session_store :active_record_store

# Configure all session options on config.action_dispatch.session_options
# Start with common options for all environments.
Rails.application.config.action_dispatch.session_options.update(
  key: "_csce606_group5_project1_session"
)

# Add production-specific options
if Rails.env.production?
  Rails.application.config.action_dispatch.session_options.update(
    domain: :all,
    tld_length: 2
  )
end
