require 'active_record'
require 'ostruct'
require 'has_publishing'


# This should be all of the rails we need
class Rails
  @@env = "draft"
  def self.env
    @@env
  end

  def self.env=(env)
    @@env = env
  end
end

class Time
  def self.zone
    OpenStruct.new(:now => Time.now)
  end
end

ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => File.join(File.dirname(__FILE__), 'has_publishing_test.db')
)


class CreateTestModels < ActiveRecord::Migration[6.0]
  def self.up
    if ActiveRecord::Base.connection.table_exists? "test_models"
      drop_table :test_models
    end

    create_table :test_models do |t|
      t.datetime :published_at
      t.datetime :embargoed_until
      t.string :kind
      t.boolean :dirty
      t.references :published

      t.timestamps
    end
  end

  def self.down
    drop_table :test_models
  end
end

CreateTestModels.migrate(:up)

class TestModel < ActiveRecord::Base
  has_publishing
end

describe "has_publishing" do

  before do
    TestModel.delete_all
  end

  subject do
    TestModel.new
  end

  describe "default configuration" do
    it { HasPublishing.config.scope_records.should be_true }
    it { HasPublishing.config.published_rails_environment.should eq "published" }
  end


  describe "scopes" do

    describe "default scope" do
      context "scope_records is false" do
        before do
          HasPublishing.config.scope_records = false
        end

        it "should not append any conditions" do
          TestModel.should_not_receive(:where)
          TestModel.first
        end
      end

      context "rails production is published" do
        before do
          HasPublishing.config.scope_records = true
          HasPublishing.config.published_rails_environment = "production"
          Rails.env = "production"
        end

        after do
          HasPublishing.config.scope_records = false
        end

        it "should only return published records" do
          TestModel.should_receive(:published).at_least(:once)
          TestModel.first
        end

        it "should not return embargoed records" do
          TestModel.should_receive(:not_embargoed)
          TestModel.first
        end
      end
    end

    describe "draft" do
      it "should include a draft record" do
        subject.kind = 'draft'
        subject.save

        subject.class.draft.should include subject
      end

      it "should not include a published record" do
        subject.kind = 'published'
        subject.save

        subject.class.draft.should_not include subject
      end
    end

    describe "published" do
      it "should include a published record" do
        subject.kind = 'published'
        subject.save! 
        subject.class.unscoped.published.should include subject
      end

      it "should not include a draft record" do
        subject.kind = 'draft'
        subject.save
        subject.class.published.should_not include subject
      end
    end

    describe "embargoed" do
      it "should include an embargoed record" do
        subject.embargoed_until = Time.now - 3600
        subject.save

        subject.class.embargoed.should include subject
      end

      it "should not include an embargoed record whose time has not passed" do
        subject.embargoed_until = Time.now + 5.minutes
        subject.save
        subject.class.embargoed.should_not include subject
      end
    end

    describe "non_embargoed" do
      it "should include a non embargoed record" do
        subject.save
        subject.class.not_embargoed.should include subject
      end

      it "should include a non-expired embargoed record" do
        subject.embargoed_until = Time.now - 3600
        subject.save
        subject.class.not_embargoed.should include subject
      end

      it "should not include an embargoed record" do
        subject.embargoed_until = Time.now + 3600
        subject.save
        subject.class.not_embargoed.should_not include subject
      end
    end
  end

  describe "associations" do
    it { subject.methods.should include :draft }
    it { subject.methods.should include :published_id }
  end

  describe "callbacks" do
    it "should set the default status to draft" do
      subject.save
      subject.kind.should eq "draft"
    end

    it "should not change the status if it is already set" do
      subject.kind = "published"
      subject.save
      subject.kind.should_not eq "draft"
    end

    it "should set the record to dirty once it has been created and is already published" do
      subject.kind = "draft"
      subject.published = TestModel.new(:updated_at => Time.now)  
      subject.save
      subject.dirty.should be_true
    end
  end

  describe "instance methods" do
    describe "publish!" do
      before do
        subject.kind = "draft"
        subject.save
      end

      context "first time publishing" do
        it "should create a published record" do
          subject.class.should_receive(:create!).and_call_original
          subject.publish!
        end

        it "should set the inverse record on the original" do
          expect {
            subject.publish!
          }.to change(subject, :published).to(an_instance_of(TestModel))
        end

        it "should record the published date" do
          expect {
            subject.publish!
          }.to change(subject, :published_at).to(an_instance_of(Time))
        end
      end
    end

    describe "withdraw!" do
      before do
        subject.kind = 'draft'
        subject.save
      end

      it "should not withdraw if the record is not published" do
        subject.withdraw!.should be_false
      end

      it "should withdraw the published record" do
        subject.publish!
        subject.withdraw!
        subject.withdrawn?.should be_true
      end
    end

    describe "draft?" do
      it { subject.kind = "draft"; subject.draft?.should be_true }
      it { subject.kind = "published"; subject.draft?.should be_false }
    end

    describe "published?" do
      context "record is draft, inverse is published" do
        before do
          subject.kind = 'draft'
          subject.published = TestModel.new(:kind => "published")
        end

        it { subject.published?.should be_true }
      end

      context "record is published" do
        it { subject.kind = "published"; subject.published?.should be_true }
        it { subject.kind = "draft"; subject.published?.should be_false }
      end
    end

    describe "ever_published?" do
      before do
        subject.save
      end
      
      context "record is published" do
        before do
          subject.publish!
        end

        it { subject.ever_published?.should be_true }
      end

      context "record is withdrawn" do
        before do
          subject.publish!
          subject.withdraw!
        end

        it { subject.ever_published?.should be_true }
      end

      it { subject.ever_published?.should be_false }
    end

    describe "under_embargo?" do
      before do
        subject.publish!
      end

      context "record is published and embargo has finished" do
        before do
          subject.embargoed_until = Time.now + 5.minutes
          subject.save
        end

        it { subject.under_embargo?.should be_true }
      end

      context "embargo is not present" do
        it { subject.under_embargo?.should be_false }
      end

      it { subject.under_embargo?.should be_false }
    end

    describe "withdrawn?" do
      context "record is draft, inverse is withdrawn" do
        before do
          subject.kind = 'draft'
          subject.published = TestModel.new(:kind => "withdrawn")
        end

        it { subject.withdrawn?.should be_true }
      end

      context "record is withdrawn" do
        it { subject.kind = "withdrawn"; subject.withdrawn?.should be_true }
        it { subject.kind = "draft"; subject.withdrawn?.should be_false }
      end
    end
  end
end