require 'data_mapper' if not defined?(DataMapper)

#
module ContentManagerSystem

  #
  # It represents a taxonomy or vocabulary 
  #
  class Taxonomy
    include DataMapper::Resource

    storage_names[:default] = 'cms_taxonomies'

    property :id, String, :field => 'id', :length => 20, :key => true    
    property :name, String, :field => 'name', :length => 50
    property :description, String, :field => 'description', :length => 256
    property :weight, Integer, :field => 'weight', :default => 0
    
    has n, :taxonomy_content_types, 'TaxonomyContentType', :child_key => [:taxonomy_id, :content_type_id], :parent_key => [:id], :constraint => :destroy

    alias old_save save

    #
    # Assign a new usergroup list to the block
    #
    # @param [Array] new_content_types
    #
    #   A list of ContentType identifiers
    #
    #
    def assign_content_types(new_content_types)
        
      # Remove all taxonomy content types which doesn't belong to the taxonomy
      TaxonomyContentType.all(:taxonomy => {:id => id}, 
                              :content_type => {:id.not => new_content_types}).destroy

      # Insert the new taxonomy content types
      new_content_types.each do |ct_id|     
          if not TaxonomyContentType.get(id, ct_id)
            TaxonomyContentType.create({:taxonomy => self, :content_type => ContentType.get(ct_id) })
          end
      end
      
      taxonomy_content_types.reload
      
    end
        
    #
    #
    #
    def save
      
      old_save
    
    end

  end #Taxonomy
end