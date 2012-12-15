require 'has_publishing/version'
require 'has_publishing/class_methods'
require 'has_publishing/instance_methods'
require 'has_publishing/configuration'


class << ActiveRecord::Base
  def has_publishing

    # Include instance methods
    include HasPublishing::InstanceMethods

    # Include dynamic class methods
    extend HasPublishing::ClassMethods


    scope :published, lambda { where(:kind => "published").not_embargoed }
    scope :draft, where(:kind => 'draft')

    scope :embargoed, lambda { where("embargoed_until IS NOT NULL AND ? > embargoed_until", Time.zone.now.round) }
    scope :not_embargoed, lambda { where("embargoed_until IS NULL OR embargoed_until < ?", Time.zone.now.round) }

    before_create :set_draft
    after_save :set_dirty

    belongs_to :published, :class_name => self.name, :foreign_key => :published_id, :dependent => :destroy
    has_one :draft, :class_name => self.name, :foreign_key => :published_id

  end
end