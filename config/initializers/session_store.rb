# Rails.application.config.session_store :active_record_store, key: "_csce606_group5_project1_session"

if Rails.env.production?
  Rails.application.config.session_store :active_record_store, {
    key: "_csce606_group5_project1_session",
    domain: :all,
    tld_length: 2
  }
else
  Rails.application.config.session_store :active_record_store, key: "_csce606_group5_project1_session"
end
