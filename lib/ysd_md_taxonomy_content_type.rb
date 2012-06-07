require 'data_mapper' if not defined?(DataMapper)

#
module ContentManagerSystem

  #
  # It represents the taxonomies that can be used for the content types 
  #
  class TaxonomyContentType
    include DataMapper::Resource

    storage_names[:default] = 'cms_taxonomies_content_types'

    belongs_to :taxonomy, 'Taxonomy', :child_key => ['taxonomy_id'], :parent_key => ['id'], :key => true
    belongs_to :content_type, 'ContentType', :child_key => ['content_type_id'], :parent_key => ['id'], :key => true

    # post is an alias for the save method
    alias old_save save

    #
    # Before save hook
    #
    def save
     
      # It makes sure to get content type and taxonomy from the storage
      if (self.content_type and not self.content_type.saved?)
        attributes = self.content_type.attributes.clone
        attributes.delete(:id)
        self.content_type = ContentType.first_or_create({:id => self.content_type.id}, attributes ) 
      end
      
      if (self.taxonomy and not self.taxonomy.saved?)
        attributes = self.taxonomy.attributes.clone
        attributes.delete(:id)
        self.taxonomy = Taxonomy.first_or_create({:id => self.taxonomy.id}, attributes)
      end
      
      # Invokes the old save 
      old_save 
       
    end

  end #Taxonomy
end