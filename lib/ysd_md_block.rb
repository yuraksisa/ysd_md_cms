require 'data_mapper' if not defined?(DataMapper)

module ContentManagerSystem
  # It represents a block, that is, a chunk of data
  class Block
    include DataMapper::Resource
    
    storage_names[:default] = 'cms_blocks'
    
    property :id, Serial, :field => 'id', :key => true
    
    property :name, String, :field => 'name', :length => 32
    property :module_name, String, :field => 'module_name', :length => 64
    
    property :theme, String, :field => 'theme', :length => 32 
    property :region, String, :field => 'region', :length => 64 # The region where the block is represented
    
    property :weight, Integer, :field => 'weight', :default => 0
    property :title, String, :field => 'title', :length => 64
    
    property :show_block_on_anonymous_user, Boolean, :field => 'show_block_on_anonymous_user', :default => true
    has n, :block_usergroups, 'BlockUserGroup', :child_key => [:block_id, :usergroup_group] , :parent_key => [:id], :constraint => :destroy
    
    property :show_block_on_page, Integer, :field => 'show_block_on_page', :default => 1 # 1-all pages except list 2-only listed pages
    property :show_block_on_page_list, Text, :field => 'show_block_on_page_list'
    
    alias old_save save
    
    #
    # Check if the block should be shown
    #
    # show_block_on_anonymous_user => The block will be shown if there is not a connected user
    # 
    # @return [Boolean]
    #   true if the block can be show for the user and path
    #
    def can_be_shown?(user, path)
    
      check_user?(user) and check_path?(path)    
    
    end
    
    #
    # Assign a new usergroup list to the block
    #
    # @param [Array] new_usergroups
    #
    #   A list of Users::UserGroup identifiers
    #
    #
    def assign_usergroups(new_usergroups)
        
      # Remove all block user groups which doesn't belong to the block
      BlockUserGroup.all(:block => {:id => id}, 
                         :usergroup => {:group.not => new_usergroups}).destroy

      # Insert the new block usergroups
      new_usergroups.each do |user_group|     
          if not BlockUserGroup.get(id, user_group)
            BlockUserGroup.create({:block => self, :usergroup => Users::UserGroup.get(user_group) })
          end
      end
      
      block_usergroups.reload
      
    end
                
    #
    #
    #
    def save
                      
      old_save
      
    end
    
    
    #
    # Rehash blocks : Create news and delete those which does not exist
    #
    # @param [Array] blocks
    #  Array of Hashes which the blocks definitions:
    #    {:name => 'myblock', :module_name => 'module where the block is defined'}
    #
    def self.rehash_blocks(blocks)
    
      # Remove the not existing blocks
      Block.all.each do |block|
        x = blocks.delete_if do |b| b[:name] == block.name and b[:module_name] == block.module_name and block[:theme] == block.theme end
        block.destroy if not x 
      end
      
      # Create the not existing blocks
      blocks.each do |block| 
        Block.first_or_create(block)    
      end
    
    end
    
    private
     
    #
    # Check if the block is shown for the user
    # 
    def check_user?(user)
   
      can_show = false
      
      # check the user    
      if show_block_on_anonymous_user
        can_show = user.nil?
      end
        
      if (not can_show) and (not user.nil?)
        can_show = (BlockUserGroup.count('block.id'=>id, 'usergroup.group'=>user.usergroups) > 0)
      end
      
      return can_show
      
    end
    
    #
    # Check if the block can be shown in this path
    #
    def check_path?(path)
    
      process_pages = show_block_on_page_list.split
      
      can_show = true
      
      if process_pages.length > 0 and show_block_on_page == 2
        can_show = false
      end
         
      process_pages.each do |expression|
        reg_exp = Regexp.new(expression)
        if show_block_on_page == 1 and path.match(reg_exp) # all but listed
          can_show = false
          break            
        end  
        if show_block_on_page == 2 and path.match(reg_exp) # only listed
          can_show = true
          break
        end
      end
      
      return can_show
      
    end
    
  end
end   
    