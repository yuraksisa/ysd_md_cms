require 'spec_helper'
#
# Describing the behaviour of the content class
#
describe ContentManagerSystem::ContentType do 

  #
  # Loads data before executing any test
  #
  before :all do

    @user_group = Users::Group.create({:group => 'ct_user' , :name => 'Users' , :description => 'Generic users'})
    @staff_group = Users::Group.create({:group => 'ct_staff', :name => 'Staff', :description => 'Staff'})
    
    @user = Users::RegisteredProfile.create({:username => 'ct_test', :password => '1234', :usergroups => [@user_group]})
    @admin_user = Users::RegisteredProfile.create({:username => 'ct_admin', :password => '1234', :usergroups => [@staff_group]})

    @content_type = ContentManagerSystem::ContentType.new({:id => 'ct_page', :name => 'Page', :description => 'Page',
                                                           :publishing_workflow_id => 'standard', 
                                                           :usergroups => [@user_group]
                                                          })

  end

  it "should create a full content type" do

    @content_type.save

    loaded_content_type = ContentManagerSystem::ContentType.get('ct_page')

    loaded_content_type.usergroups.size.should == 1
    loaded_content_type.content_type_user_groups.size.should == 1
    loaded_content_type.usergroups.include?(@user_group).should be_true
    loaded_content_type.can_be_created_by?(@user).should be_true
    loaded_content_type.can_be_created_by?(@admin_user).should be_false

  end

end