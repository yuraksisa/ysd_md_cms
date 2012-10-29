require 'data_mapper' unless defined?DataMapper
require 'ysd-md-profile' unless defined?Users::UserGroup

module ContentManagerSystem
  #
  # The user groups which can create a content type
  #
  class ContentTypeUserGroup
    include DataMapper::Resource
  
    storage_names[:default] = 'cms_content_types_usergroups'
  
    belongs_to :content_type, 'ContentManagerSystem::ContentType', :child_key => [:content_type_id], :parent_key => [:id], :key => true
    belongs_to :usergroup, 'Users::UserGroup', :child_key => [:usergroup_group], :parent_key => [:group], :key => true

    # post is an alias for the save method
    alias old_save save

    #
    # Before save hook
    #
    def save
     
      if (self.content_type and not self.content_type.saved?)
        attributes = self.content_type.attributes.clone
        attributes.delete(:id)
        self.content_type = ContentType.first_or_create({:id => self.content_type.id}, attributes)
      end

      # It makes sure to get content type and taxonomy from the storage
      if (self.usergroup and not self.usergroup.saved?)
        attributes = self.usergroup.attributes.clone
        attributes.delete(:group)
        self.usergroup = Users::UserGroup.first_or_create({:group => self.usergroup.group}, attributes ) 
      end
      
      
      # Invokes the old save 
      old_save 
       
    end


      
  end
end