module HasPublishing
  module InstanceMethods


    # Publishing "states"
    #   Draft         = draft only (no published version, i.e new)
    #   Dirty         = published + draft dirty (this is a kind of Draft state,
    #                                            has been published but draft has been edited since)
    #   Published     = published + draft NOT dirty
    #   Under imbargo = published but future dated (embargo_until field)


    def publish!(extra_attrs = {})
      self.save! if self.new_record?
      self.class.unscoped {
        return false unless draft?
        if published.nil? # first time publishing
          published_obj = self.class.create!(attributes.merge(:kind => 'published', :published_at => Time.zone.now, :dirty => nil).merge(extra_attrs))
          self.published_id = published_obj.id
        else
          published.update_attributes!(attributes.merge(:kind => 'published', :published_id => nil, :published_at => Time.zone.now, :dirty => nil).merge(extra_attrs))
        end
        self.class.record_timestamps = false # want same updated_at
        self.save! # make sure this model is in sync
        update_attributes!(:published_at => published.published_at, :dirty => false, :updated_at => published.updated_at)
        self.class.record_timestamps = true
        return published
      }
    end

    def withdraw!
      self.class.unscoped {
        return false unless draft? && ever_published?
        self.class.record_timestamps = false # want same updated_at
        published.update_attributes!(:kind => 'withdrawn') and update_attributes!(published.attributes.merge({:kind => 'draft', :published_id => published_id, :published_at => nil, :dirty => false}))
        self.class.record_timestamps = true
        return published
      }
    end

    def draft?
      kind == 'draft'
    end

    def published?
      self.class.unscoped { (draft? && published && published.kind == 'published') || kind == 'published' }
    end

    def withdrawn?
      self.class.unscoped { (draft? && published && published.kind == 'withdrawn') || kind == 'withdrawn' }
    end

    def ever_published?
      published? || withdrawn?
    end

    def under_embargo?
      published? && embargoed_until && embargoed_until > Time.zone.now
    end

    private

    def set_dirty
      self.class.unscoped { update_attributes(:dirty => true) if draft? && published && published.updated_at != updated_at && !dirty? && !withdrawn? }
    end

    def set_draft
      self.kind = 'draft' if kind.nil?
    end

  end
end
