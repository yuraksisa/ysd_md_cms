require 'data_mapper' unless defined?DataMapper
require 'ysd-md-profile' unless defined?Users::Group

module ContentManagerSystem
  #
  # It represents the user's group that have permission to view the block
  #
  class BlockUserGroup
    include DataMapper::Resource
  
    storage_names[:default] = 'cms_blocks_usergroup'
  
    belongs_to :block, 'Block', :child_key => ['block_id'], :parent_key => ['id'], :key => true
    belongs_to :usergroup, 'Users::Group', :child_key => ['usergroup_group'], :parent_key => ['group'], :key => true

    # post is an alias for the save method
    alias old_save save

    #
    # Before save hook
    #
    def save
    
      if (self.usergroup and not self.usergroup.saved?)
        self.usergroup = Users::Group.get(self.usergroup.group)
      end
      
      if (self.block and not self.block.saved?)
        self.block = Block.get(self.block.id)
      end
      
      old_save 
       
    end

  end
end