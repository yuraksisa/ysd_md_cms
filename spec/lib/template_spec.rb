require 'spec_helper'

describe ContentManagerSystem::Template do


  describe ".find_by_name" do

    before :all do
      @template = ContentManagerSystem::Template.create({:name => 'booking.js', 
      	:text => 'var date = new Date(2012,10,1);' })
    end

    after :all do
      @template.destroy
    end

    context "find result" do

      subject { ContentManagerSystem::Template.find_by_name('booking.js') }
      it { should_not be_nil }
  
    end

    context "not find results" do

      subject { ContentManagerSystem::Template.find_by_name('no_name') }
      it { should be_nil}

    end

  end

end