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
    
    #
    # Rehash blocks : Create news and delete those which does not exist
    #
    # @param [Array] blocks
    #  Array of Hashes which the blocks definitions:
    #    {:name => 'myblock', :module_name => 'module where the block is defined'}
    #
    def self.rehash_blocks(blocks)
    
      puts "blocks : #{blocks.to_json}"
    
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
    
  end
end   
    