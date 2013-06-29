require 'data_mapper' unless defined?DataMapper

module ContentManagerSystem
  #
  # It represents the content types to which the block will be shown
  #
  class BlockContentType
    include DataMapper::Resource
  
    storage_names[:default] = 'cms_blocks_content_types'
    
    belongs_to :block, 'Block', :child_key => [:block_id], :parent_key => [:id], :key => true
    belongs_to :content_type, 'ContentType', :child_key => [:content_type_id], :parent_key => [:id], :key => true

    def save
    
      if (self.content_type and not self.content_type.saved?)
        self.content_type = ContentType.get(self.content_type.id)
      end
      
      if (self.block and not self.block.saved?)
        self.block = Block.get(self.block.id)
      end
      
      super 
       
    end

  end
end