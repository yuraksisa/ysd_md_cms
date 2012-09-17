require 'data_mapper' unless defined?DataMapper
require 'ysd-md-profile' unless defined?Users::UserGroup

module ContentManagerSystem
  # It represents a block, that is, a chunk of data
  class BlockUserGroup
    include DataMapper::Resource
  
    storage_names[:default] = 'cms_blocks_usergroup'
  
    belongs_to :block, 'Block', :child_key => ['block_id'], :parent_key => ['id'], :key => true
    belongs_to :usergroup, 'Users::UserGroup', :child_key => ['usergroup_group'], :parent_key => ['group'], :key => true

    # post is an alias for the save method
    alias old_save save

    #
    # Before save hook
    #
    def save
     
      # It makes sure to get content type and taxonomy from the storage
      if (self.usergroup and not self.usergroup.saved?)
        attributes = self.usergroup.attributes.clone
        attributes.delete(:group)
        self.usergroup = Users::UserGroup.first_or_create({:group => self.usergroup.group}, attributes ) 
      end
      
      if (self.block and not self.block.saved?)
        attributes = self.block.attributes.clone
        attributes.delete(:id)
        self.block = Block.first_or_create({:id => self.block.id}, attributes)
      end
      
      # Invokes the old save 
      old_save 
       
    end


      
  end
end