require 'data_mapper' unless defined?DataMapper
require 'ysd_md_profile' unless defined?Users::Group

module ContentManagerSystem
  #
  # The user groups that can create a content type
  #
  class ContentTypeUserGroup
    include DataMapper::Resource
  
    storage_names[:default] = 'cms_content_types_usergroups'
  
    belongs_to :content_type, 'ContentType', :child_key => [:content_type_id], :parent_key => [:id], :key => true
    belongs_to :usergroup, 'Users::Group', :child_key => [:usergroup_group], :parent_key => [:group], :key => true

    alias old_save save

    #
    def save
     
      if (self.content_type and not self.content_type.saved?)
        self.content_type = ContentType.get(self.content_type.id)
      end

      if (self.usergroup and not self.usergroup.saved?)
        self.usergroup = Users::Group.get(self.usergroup.group)
      end
      
      old_save 
       
    end
      
  end
end