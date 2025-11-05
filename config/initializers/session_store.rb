Rails.application.config.session_store :active_record_store

# Configure all session options on config.action_dispatch.session
# This hash will be used to create the session.
Rails.application.config.action_dispatch.session = {
  key: "_csce606_group5_project1_session"
}

# Add production-specific options by merging them into the hash
if Rails.env.production?
  Rails.application.config.action_dispatch.session.merge!(
    domain: :all,
    tld_length: 2
  )
end
