require 'spec_helper'

#
# Describing the behaviour of the content class
#
describe ContentManagerSystem::Content do 

  #
  # Loads data before executing any test
  #
  before :all do

    @user_group = Users::Group.create({:group => 'user' , :name => 'Users' , :description => 'Generic users'})

    @content_type = ContentManagerSystem::ContentType.create({:id => 'page', :name => 'Page', :description => 'Page',
                                                              :publishing_workflow_id => 'standard', :content_type_user_groups => [{:usergroup => @user_group}]})

    @taxonomy = ContentManagerSystem::Taxonomy.create({:id => 'countries', :name => 'Countries', :description => 'Countries taxonomy', :weight => 0,
    	                                                :taxonomy_content_types => [{:content_type => @content_type}]})

    @term_spain = ContentManagerSystem::Term.create({:description => 'Spain', :weight => 0, :taxonomy => @taxonomy })
    @term_france = ContentManagerSystem::Term.create({:description => 'France', :weight => 0, :taxonomy => @taxonomy })
    @term_ecuador = ContentManagerSystem::Term.create({:description => 'Ecuador', :weight => 0, :taxonomy => @taxonomy })

    @new_content = ContentManagerSystem::Content.new({:title => 'foo', :body => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum eu.', 
      	                                              :subtitle => 'subtitle', :description => 'description',
   	                                                  :summary => 'summary', :keywords => 'word1, word2',
   	                                                  :language => 'en', :author => 'me',
   	                                                  :content_type => {:id => 'page'},
   	                                                  :content_categories => [{:category => {:id => @term_spain.id}}, {:category => {:id => @term_france.id}}] })

    @new_content_categories = ContentManagerSystem::Content.new({:title => 'foo', :body => 'bar', 
      	                                              :subtitle => 'subtitle categories', :description => 'description categories',
   	                                                  :summary => 'summary', :keywords => 'word1, word2',
   	                                                  :language => 'en', :author => 'me',
   	                                                  :content_type => {:id => 'page'},
   	                                                  :categories => [{:id => @term_spain.id}, {:id => @term_france.id}]})
   
    @new_content_not_symbolized =  ContentManagerSystem::Content.new({'title' => 'foo', 'body' => 'bar', 
      	                                              'subtitle' => 'subtitle', 'description' => 'description',
   	                                                  'summary' => 'summary', 'keywords' => 'word1, word2',
   	                                                  'language' => 'en', 'author' => 'me',
   	                                                  'content_type' => {'id' => 'page'},
   	                                                  'content_categories' => [{'category' => {'id' => @term_spain.id}}, {'category' => {'id' => @term_france.id}}] }.symbolize_keys)
    

  end



  it "should create a full content with content categories from content and categories hash" do
   
    @new_content.save

    loaded_content = ContentManagerSystem::Content.get(@new_content.id)

    loaded_content.content_type.should == @content_type
    loaded_content.content_categories.size.should == 2
    loaded_content.categories.size.should == 2
    loaded_content.categories.include?(@term_spain).should

  end

  it "should create a full content with categories and updates the content categories" do
   
   @new_content_categories.save

   loaded_content = ContentManagerSystem::Content.get(@new_content_categories.id)
   loaded_content.categories.size.should == 2

   loaded_content.attributes=({:categories => [{:id => @term_spain.id}]})
   loaded_content.save

   loaded_content = ContentManagerSystem::Content.get(@new_content_categories.id)
   loaded_content.categories.size.should == 1

   @new_content_categories = ContentManagerSystem::Content.get(@new_content_categories.id)
   @new_content_categories.destroy.should be_true
   ContentManagerSystem::Content.get(@new_content_categories.id).should be_nil

  end



  it "should export the content to json" do

    @new_content.save
    loaded_content = ContentManagerSystem::Content.get(@new_content.id)

    json_content = loaded_content.to_json

    #json_content["categories"]

    puts "TO JSON : #{loaded_content.to_json}"
    
    #
    # TODO check that categories, categories_info and categories_by_taxonomy are built
    #

  end

  it "should create a full content with not symbolized keys" do
    
    @new_content_not_symbolized.save

    loaded_content = ContentManagerSystem::Content.get(@new_content_not_symbolized.id)

    loaded_content.content_type.should == @content_type
    loaded_content.content_categories.size.should == 2
    loaded_content.categories.size.should == 2
    loaded_content.categories.include?(@term_spain).should
    
    @new_content_not_symbolized.destroy

  end
  
  
  it "should update content categories (drop one and add another)" do

    @new_content.save

    loaded_content = ContentManagerSystem::Content.get(@new_content.id)
    
    #loaded_content.attributes={'content_categories' => [{'category' => {'id' => @term_spain.id}}, {'category' => {'id' => @term_ecuador.id}}] }.symbolize_keys
    loaded_content.attributes={'categories' => [{'id' => @term_spain.id},{'id' => @term_ecuador.id}] }.symbolize_keys

    loaded_content.save

    loaded_content = ContentManagerSystem::Content.get(@new_content.id)

    loaded_content.content_type.should == @content_type
    loaded_content.content_categories.size.should == 2
    loaded_content.categories.size.should == 2
    loaded_content.categories.include?(@term_spain).should
    loaded_content.categories.include?(@term_ecuador).should
    loaded_content.categories.include?(@term_france).should be_false

  end  
  
  #
  # Querying contents
  #

  it "should find contents by category (through the content class)" do
  
    @new_content.save
   
    ContentManagerSystem::Content.find_by_category(@term_spain.id).size.should == 1
  
  end

  it "should find contents by category (through the comparison)" do

    @new_content.save

    query = Conditions::Comparison.new('content_categories.category.id', '$eq', @term_spain.id).build_datamapper(ContentManagerSystem::Content)
   
    query.size.should == 1

  end

  it "should find contents by category (through SQL subselect)" do
  
    @new_content.save
    ContentManagerSystem::Content.all(:conditions => ['id in (select content_id from cms_content_categories where term_id = ?)', @term_spain.id]).size.should == 1
  
  end

  it "should find contents using a Comparison" do

    @new_content.save

    query = Conditions::JoinComparison.new('$and', 
   	           [Conditions::Comparison.new('author','$eq','me'), 
   	           	Conditions::Comparison.new('summary', '$eq', 'summary')]).build_datamapper(ContentManagerSystem::Content)
   
    query.size.should == 1

  end

  it "should find contents using full text search" do

    @new_content.save

    ContentManagerSystem::Content.search("elit").size.should == 1

  end	
	
end