module HasPublishing
  module ClassMethods
    # This default scope allows published and draft viewing modes to share the
    # same code. This is good. However if you need to access the other, draft
    # from published or published from draft e.g from admin for editing, then
    # you must explicitly use .unscoped to remove the default scope.

    def default_scope
      if Rails.env == (HasPublishing.config.published_rails_environment || "production")
        where("#{self.table_name}.kind = 'published'").
        where([
          "#{self.table_name}.embargoed_until IS NULL OR ? > #{self.table_name}.embargoed_until", 
          Time.zone.now.round
        ])
      else
        where(:kind => "draft")
      end
    end
  end
end