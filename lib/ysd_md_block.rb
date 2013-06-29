require 'data_mapper' if not defined?(DataMapper)

module ContentManagerSystem
  #
  # It represents a block, a chunk of information that is used to build a page
  # 
  # It's the same as Drupal Block and it's also named widget on some products as WordPress
  #
  class Block
    include DataMapper::Resource
    
    storage_names[:default] = 'cms_blocks'
    
    property :id, Serial, :field => 'id', :key => true
    
    property :name, String, :field => 'name', :length => 50
    property :description, String, :field => 'description', :length => 256
    property :module_name, String, :field => 'module_name', :length => 64
    
    property :theme, String, :field => 'theme', :length => 32 
    property :region, String, :field => 'region', :length => 64 # The region where the block is represented
    
    property :weight, Integer, :field => 'weight', :default => 0
    property :title, String, :field => 'title', :length => 64
    property :show_title, Boolean, :field => 'show_title', :default => false

    property :visibility_condition, Text, :field => 'visibility_condition'

    property :show_block_on_page, Integer, :field => 'show_block_on_page', :default => 1 # 1-all pages except list 2-only listed pages
    property :show_block_on_page_list, Text, :field => 'show_block_on_page_list'
    
    has n, :block_usergroups, 'BlockUserGroup', :child_key => [:block_id] , :parent_key => [:id], :constraint => :destroy
    has n, :usergroups, 'Users::Group', :through => :block_usergroups, :via => :usergroup

    has n, :block_content_types, 'BlockContentType', :child_key => [:block_id], :parent_key => [:id], :constraint => :destroy
    has n, :content_types, 'ContentType', :through => :block_content_types, :via => :content_type
    
    #
    # Override the save method to check the usergroups associated to the block
    #
    def save
      
      transaction do |transaction|
        check_usergroups! if self.usergroups and (not self.usergroups.empty?)
        check_content_types! if self.content_types and (not self.content_types.empty?)
        super
        transaction.commit
      end

    end

    #
    # Check if the block should be shown
    # 
    # @param [User] the user
    # @param [String] the URL from which the block will be shown
    # @param [String] the content type
    #
    # @return [Boolean]
    #   true if the block can be show for the user and path
    #
    def can_be_shown?(user, path, content_type_id)
    
      if visibility_condition.nil? or visibility_condition.empty?
        check_user?(user) and check_path?(path) and check_content_type_id?(content_type_id) 
      else
        condition = visibility_condition.gsub('user','#{check_user?(user)}').
          gsub('path','#{check_path?(path)}').
          gsub('content_type','#{check_content_type_id?(content_type_id)}')
        #p "CONDITION :#{condition} *#{content_type_id}* : #{eval('"'<<condition<<'"')} : #{eval(eval('"'<<condition<<'"'))}"
        eval(eval('"'<<condition<<'"'))
      end   
    
    end
                   
    #
    # Create new blocks and delete those which does not exist
    #
    # @param [Array] blocks
    #  Array of Hashes which the blocks definitions:
    #    {:name => 'myblock', :module_name => 'module where the block is defined' , :theme => 'theme'}
    #
    def self.rehash_blocks(blocks)
      
      # Remove the not existing blocks
      Block.all.each do |block| 
        unless blocks.index {|b| b[:name] == block.name and b[:module_name] == block.module_name.to_sym and b[:theme]==block.theme}
          block.destroy
        end 
      end
      
      # Create the not existing blocks
      blocks.each do |block| 
        Block.first_or_create({:name => block[:name]}, block)    
      end
    
    end
    
    #
    # Retrive the active blocks for some regions on a theme
    #
    # @param [Theme] The theme
    # @param [Array] The regions
    # @param [User] The user
    # @param [String] The path
    # @param [String] content type id
    #
    # @return [Hash] The key is the region and the value is an array of Block
    # to show on the region
    #
    def self.active_blocks(theme, regions, user, path, content_type_id)
      
      result = {}

      blocks = all(:conditions => {:theme => theme.name,
        :region => regions}, :order => [:region.asc, :weight.asc])

      blocks.each do |block|
        region = block.region.to_sym
        result.store(region, []) unless result.has_key?(region)
        result[region].push(block) if block.can_be_shown?(user, path, content_type_id)          
      end

      return result

    end

    #
    # Exporting the profile
    #  
    def as_json(options={})

      relationships = options[:relationships] || {}
      relationships.store(:usergroups, {})
      relationships.store(:content_types, {})

      super(options.merge(:relationships => relationships))

    end

    private
    
    #
    # Preprocess the user groups and loads if they exist
    #
    def check_usergroups!

      self.usergroups.map! do |ug|
        if (not ug.saved?) and loaded_usergroup = Users::Group.get(ug.group)
          loaded_usergroup
        else
          ug
        end 
      end

    end

    #
    # Preprocess the content types and loads if they exist
    #
    def check_content_types!

      self.content_types.map! do |ct|
        if (not ct.saved?) and loaded_content_type = ContentType.get(ct.id)
          loaded_content_type
        else
          ct
        end
      end

    end


    #
    # Check if the block is shown for the user
    # 
    def check_user?(user)
   
      can_show = false
              
      if not user.nil?
        can_show = (BlockUserGroup.count('block.id'=>id, 'usergroup.group' => user.usergroups.map{|ug| ug.group} ) > 0)
      end
      
      return can_show
      
    end
    
    #
    # Check if the block can be shown in this path
    #
    def check_path?(path)
      
      can_show = true
      
      unless show_block_on_page_list.nil? and show_block_on_page_list.to_s.strip.length == 0
        
        process_pages = show_block_on_page_list.split
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
     
      end
      
      return can_show
      
    end
    
    #
    # Check if the block can be shown for the content_type
    #
    def check_content_type_id?(content_type_id) 

       #content_type_id.nil? or
       BlockContentType.count('block.id' => id) == 0 or
       BlockContentType.count('block.id' => id, 'content_type.id' => content_type_id) > 0

    end

  end
end   
    