require 'spec_helper'
require 'ysd_md_translation'

describe ContentManagerSystem::ContentTranslation do

  describe ".translate" do
    
    before :all do

      @translation_language = Model::Translation::TranslationLanguage.create({:code => 'en', 
          :description => 'English'})
      
      @user_group = Users::Group.create({:group => 'trans_user' , :name => 'Users' , 
          :description => 'Generic users'})	
      
      @content_type = ContentManagerSystem::ContentType.create({:id => 'trans_page', 
          :name => 'Page', 
          :description => 'Page', 
          :publishing_workflow_id => 'standard', 
          :usergroups => [@user_group]})

    end

    after :all do

      @translation_language.destroy if @translation_language
      @user_group.destroy if @user_group
      @content_type.destroy if @content_type

    end

    context "no categorized content" do

      before :all do

        @content = ContentManagerSystem::Content.create({:title => 'foo',
          :body => 'bar', :content_type => @content_type})

        ContentManagerSystem::Translation::ContentTranslation.create_or_update(
      	  @content.id, 'en', 
      	  :title => 'foo - en', :body => 'bar - en')
      end

      after :all do
        @content.destroy if @content
      end

      subject do
        @content.translate(:en)
      end

      it { should_not be_nil }
      its(:title) { should == 'foo - en'}
      its(:body) { should == 'bar - en'}

    end
  
    context "categorized content" do

    end

  end

end