module HasPublishing
  include ActiveSupport::Configurable

  # Set some default config
  self.config.scope_records = true
  self.config.published_rails_environment = "published"
end