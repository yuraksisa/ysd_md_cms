require 'ysd-persistence' 
require 'ysd-md-profile' if not defined?Users
module ContentManagerSystem

  # -------------------------------------
  # It represents a content
  # -------------------------------------
  class Content
    include Persistence::Resource
    include Users::ResourceAccessControl # Extends the model to control its access
    include Auditory::AuditoryInfo       # Extends the model adding auditory
    
    property :clear_id      # The id without the language information (to create a link to the content)
    property :title         # The content title
    property :subtitle      # The content subtitle
    property :description   # The content description
    property :summary       # The content summary
    property :keywords      # The key words (important words)
          
    property :type          # The content type (it must exist the ContentManagerSystem::ContentType)
    property :categories    # The content category
    property :categories_by_taxonomy # The categories organized by taxonomy
    
    property :language      # The language in which the content has been written
    
    property :author        # The content author

    property :body          # The content

    #
    # Gets the alias path to include a link to the content
    #
    def alias_path
      the_path = ''
      if attribute_get(:clear_id)
        the_path = model.build_path(attribute_get(:clear_id))
      end
      the_path
    end
    
    #
    # Get the content categories 
    #
    # @return [Array] 
    #
    #   A list of all content categories
    # 
    def get_categories
    
      if not instance_variable_get(:@full_categories)
       
        categories_list = []
     
        if categories_by_taxonomy and categories_by_taxonomy.kind_of?Array    
          categories_by_taxonomy.each do |taxonomy, terms|
            if terms.kind_of?(Array)
              categories_list.concat(terms)   
            else
              categories_list << terms
            end               
          end
        end
        
        @full_categories = ContentManagerSystem::Term.all(:id => categories_list)
      
      end
      
      #puts "categories : #{@full_categories}"
      
      @full_categories
     
    end
    
    #
    # Retrieve the contents which belong to a category
    # 
    # @param [String] term_id
    #  The term id
    #
    def self.get_contents_by_term(term_id)
        
      result = Content.all({:conditions => {:categories => [term_id.to_i]}, :order => [['creation_date','desc']]})
      
      result
    
    end
    
    # Serializes the object to json
    #
    # Adds the categories_info
    # 
    def to_json(options={})
 
      data = attributes.clone
      data.store(:key, self.key)
      data.store(:categories_info, self.get_categories)
    
      data.to_json
  
    end 
    
    
  end #end class Content 

end #end module ContentManagerSystem

