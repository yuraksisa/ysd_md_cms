require 'spec_helper'

describe ContentManagerSystem::TextResource do

  describe ".find_by_alias" do

    before :all do
      @template = ContentManagerSystem::Template.create({:name => 'booking.js', 
      	:text => 'var date = new Date(2012,10,1);' })

      @text_resource = ContentManagerSystem::TextResource.create({:alias => '/js/booking.js',
      	:template => @template, :mime_type => 'text/css'})
    end

    after :all do
      
      @template.destroy
      @text_resource.destroy

    end

    context "find result" do

      subject { ContentManagerSystem::TextResource.find_by_alias('/js/booking.js') }
      it { should_not be_nil }
  
    end

    context "not find results" do

      subject { ContentManagerSystem::TextResource.find_by_alias('no_name') }
      it { should be_nil}

    end

  end

end