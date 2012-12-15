module HasPublishing
  module ClassMethods
    # This default scope allows published and draft viewing modes to share the
    # same code. This is good. However if you need to access the other, draft
    # from published or published from draft e.g from admin for editing, then
    # you must explicitly use .unscoped to remove the default scope.

    def default_scope
      return scoped if HasPublishing.config.scope_records == false

      if Rails.env == (HasPublishing.config.published_rails_environment)
        published
      else
        draft
      end
    end
  end
end