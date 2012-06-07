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
    #
    #
    def save
      
      # Remove all taxonomy content types which have been removed
      content_types = self.taxonomy_content_types.map do |tct| tct.content_type.id end   
      ContentManagerSystem::TaxonomyContentType.all(:taxonomy => {:id => self.id}, :content_type => {:id.not => content_types}).destroy

      # Reload all existing taxonomies content types
      self.taxonomy_content_types = self.taxonomy_content_types.map do |tct|      
        _tct = TaxonomyContentType.get(tct.taxonomy.id, tct.content_type.id)
        if _tct
          _tct
        else
          tct
        end
      end
    
      puts "saving Taxonomy #{id} tct = #{self.taxonomy_content_types.to_json}"
      
      old_save
    
    end

  end #Taxonomy
end