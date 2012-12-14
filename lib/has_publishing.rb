require 'has_publishing/version'
require 'has_publishing/class_methods'
require 'has_publishing/instance_methods'


class << ActiveRecord::Base
  def has_publishing

    # Include instance methods
    include HasPublishing::InstanceMethods

    # Include dynamic class methods
    extend HasPublishing::ClassMethods

    # This default scope allows published and draft viewing modes to share the
    # same code. This is good. However if you need to access the other, draft
    # from published or published from draft e.g from admin for editing, then
    # you must explicitly use .unscoped to remove the default scope.
    default_scope Rails.env.split('_').last == "published" ? lambda { where("#{self.table_name}.kind = 'published'").where(["#{self.table_name}.embargoed_until IS NULL OR ? > #{self.table_name}.embargoed_until", Time.zone.now.round]) } : where(:kind => "draft")

    scope :published, lambda { where("kind = 'published' AND (embargoed_until IS NULL OR ? > embargoed_until)", Time.zone.now.round) }
    scope :draft, where("kind = 'draft'")

    scope :embargoed, lambda { where("embargoed_until IS NOT NULL AND ? > embargoed_until", Time.zone.now.round) }
    scope :not_embargoed, lambda { where("embargoed_until IS NULL OR embargoed_until < ?", Time.zone.now.round) }

    before_create :set_draft
    after_save :set_dirty

    belongs_to :published, :class_name => self.name, :foreign_key => :published_id, :dependent => :destroy
    has_one :draft, :class_name => self.name, :foreign_key => :published_id

  end
end