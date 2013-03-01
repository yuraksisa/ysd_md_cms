require 'data_mapper' unless defined?(DataMapper)
module ContentManagerSystem
  # --------------------------------------------------------------
  # Contents can be categorized. A content can belong to multiple 
  # categories.
  #
  # Instances of ContentManagerSystem::ContentCategory represents
  # the categories a content belongs to.
  #
  # --------------------------------------------------------------
  class ContentCategory
    include DataMapper::Resource

    storage_names[:default] = 'cms_content_categories'
  
    belongs_to :content,  'ContentManagerSystem::Content', :child_key => [:content_id], :parent_key => [:id], :key => true
    belongs_to :category, 'ContentManagerSystem::Term', :child_key => [:term_id], :parent_key => [:id], :key => true
  
    alias old_save save
    
    #
    # Overload save method
    #
    #  Make sure that the taxonomy exists
    #
    def save
      
      if self.content and (not self.content.saved?)
       	self.content = Content.get(self.content.id)
      end
      
      if self.category and (not self.category.saved?)
        self.category = Term.get(self.category.id)
      end

      old_save
    
    end

  end
end