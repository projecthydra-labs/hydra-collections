require 'spec_helper'

describe Collection, :type => :model do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    class GenericFile < ActiveFedora::Base
      include Hydra::Collections::Collectible
    end
  end
  after(:all) do
    @user.destroy
    Object.send(:remove_const, :GenericFile)
  end

  let(:gf1) { GenericFile.create }
  let(:gf2) { GenericFile.create }

  let(:user) { @user }

  describe "#to_solr" do
    let(:collection) { Collection.new(title: "A good title", depositor: user.user_key) }

    subject { collection.to_solr }

    it "should have title and depositor information" do
      expect(subject['title_tesim']).to eq ['A good title']
      expect(subject['depositor_tesim']).to eq [user.user_key]
      expect(subject['depositor_ssim']).to eq [user.user_key]
    end

    context "with members" do
      before do
        collection.members << gf1
      end

    end
  end

  describe "#depositor" do
    before do
      subject.apply_depositor_metadata(user)
    end

    it "should have a depositor" do
      expect(subject.depositor).to eq(user.user_key)
    end
  end

  describe "the ability" do
    let(:collection) { Collection.create { |c| c.apply_depositor_metadata(user) } }

    subject { Ability.new(user) }

    it "should allow the depositor to edit and read" do
      expect(subject.can?(:read, collection)).to be true
      expect(subject.can?(:edit, collection)).to be true
    end
  end

  describe "#members" do
    it "should be empty by default" do
      expect(subject.members).to be_empty
    end

    context "adding members" do
      context "using assignment" do
        subject { Collection.create(members: [gf1, gf2]) }

        it "should have many files" do
          expect(subject.reload.members).to eq [gf1, gf2]
        end
      end

      context "using append" do
        before do
          subject.members = [gf1]
          subject.save
        end
        it "should allow new files to be added" do
          subject.reload
          subject.members << gf2
          subject.save
          expect(subject.reload.members).to eq [gf1, gf2]
        end
      end
    end


    context "removing members" do
      before do
        subject.members = [gf1, gf2]
        subject.save!
      end

      it "allows files to be removed" do
        # force the "parent_collections" to be cached:
        expect(gf1.parent_collections).to eq [subject]

        # We need to ensure that deleting causes the collection to be flushed.
        subject.reload.members.delete(gf1)
        subject.save
        expect(subject.reload.members).to eq [gf2]
      end
    end
  end

  it "should have a title" do
    subject.title = "title"
    subject.save
    expect(subject.title).to eq "title"
  end

  it "should have a description" do
    subject.description = "description"
    subject.save
    expect(subject.reload.description).to eq "description"
  end

  describe "#destroy" do
    before do
      subject.members = [gf1, gf2]
      subject.save
      subject.destroy
    end

    it "should not delete member files when deleted" do
      expect(GenericFile.exists?(gf1.id)).to be true
      expect(GenericFile.exists?(gf2.id)).to be true
    end
  end

  describe "Collection by another name" do
    before do
      class OtherCollection < ActiveFedora::Base
        include Hydra::Collection
      end

      class Member < ActiveFedora::Base
        include Hydra::Collections::Collectible
      end
    end
    after do
      Object.send(:remove_const, :OtherCollection)
      Object.send(:remove_const, :Member)
    end

    let(:member) { Member.create }
    let(:collection) { OtherCollection.new }

    before do
      collection.members << member
      collection.save
    end

    it "have members that know about the collection" do
      member.reload
      expect(member.collections).to eq [collection]
    end
  end
end
