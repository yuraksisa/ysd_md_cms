require 'data_mapper' unless defined?DataMapper
require 'base64'
require 'unicode_utils' unless defined?UnicodeUtils
require 'ysd-plugins' unless defined?Plugins::ApplicableModelAspect
require 'ysd_md_yito'
require 'ysd_md_audit' unless defined?Audit::AuditorPersistence
require 'ysd_md_rac' unless defined?Users::ResourceAccessControlPersistence
require 'ysd_md_publishable'
require 'aspects/ysd-plugins_applicable_model_aspect' unless defined?Plugins::ApplicableModelAspect
require 'ysd_md_publishing_state'
require 'ysd_md_content_translation'
require 'ysd_md_search'
require 'ysd_dm_finder'

module ContentManagerSystem

  # -------------------------------------
  # It represents a content
  # -------------------------------------
  class Content
    include DataMapper::Resource
    include Users::ResourceAccessControl             # Extends the model to Resource Access Control
    include Audit::Auditor                           # Extends the model to Audit
    include ContentManagerSystem::Publishable        # Extends the model to manage publication
    include ContentManagerSystem::ContentTranslation # Extends the model to manage translation
    include Model::Searchable                        # Searchable
    extend  Plugins::ApplicableModelAspect           # Extends the entity to allow apply aspects
    extend  Yito::Model::Finder
    
    storage_names[:default] = 'cms_contents'
    
    property :id, Serial, :field => 'id', :key => true              # The content id

    property :title, String, :field => 'title', :length => 120      # The content title
    property :body, Text, :field => 'body'                          # The content body (text)
    property :subtitle, String, :field => 'subtitle', :length => 80 # The content subtitle
    property :description, Text, :field => 'description'            # The content description
    property :summary, Text, :field => 'summary'                    # The content summary
    property :keywords, Text, :field => 'keywords'                  # The key words (important words)
    property :language, String, :field => 'language', :length => 3  # The language in which the content has been written
    property :author, String, :field => 'author', :length => 80     # The content author

    property :alias, String, :field => 'alias', :length => 80       # An URL alias to the content

    belongs_to :content_type, :child_key => [:type] , :parent_key => [:id] 
    
    has n, :content_categories, 'ContentCategory', :child_key => [:content_id], :parent_key => [:id], :constraint => :destroy #, :through => :content_categories, :via => :category
    has n, :categories, 'Term', :through => :content_categories, :via => :category # To access directly to the term (instead on passing by ContentCategory)
    
    searchable [:title, :subtitle, :body, :description, :summary]

    alias old_save save 

    #
    # Override save to load the content type if it's necessary
    #
    def save
      
      transaction do |transaction|
        
        check_content_type! if self.content_type # Update the content type
        check_categories!   if self.categories and not self.categories.empty? # Update the categories

        old_save

        transaction.commit

      end

    end

    # Hooks

    before :create do
      
      if self.alias.nil? or self.alias.empty?     
        self.alias = File.join('/', self.content_type.id.downcase, Time.now.strftime('%Y%m%d') , UnicodeUtils.nfkd(self.title).gsub(/[^\x00-\x7F]/,'').gsub(/\s/,'-'))
      end

    end

    # ========================= Finders ===========================
        
    #
    # Retrieve the tagged contents
    # 
    # @param [String] term_id
    #  The term id
    #
    def self.find_by_category(term_id)
      Content.all(:content_categories => {:category => {:id => term_id}}, :order => [:creation_date.desc])
    end    
    
    # ============== Instance methods =====================

    #
    # Overwritten to initialize the publishing workflow when the type is assigned
    #
    def attribute_set(name, value) 
      
      super(name, value)
      
      if (name.to_sym == :content_type) 
        check_content_type!
        check_publishing_workflow!
      end

    end
   
    #
    # Overwritten to initialize the publishing workflow when the type is assigned
    #
    def attributes=(attributes)
      
      attributes.symbolize_keys! 

      super(attributes)

      if attributes.has_key?(:content_type) and not attributes.has_key?(:publishing_workflow)
        check_content_type!
        check_publishing_workflow!
      end

    end

    # ============ Exporting the objects =================
    
    #
    # Serializes the object to json
    # 
    def as_json(options={})
 
      methods = options[:methods] || []
      methods << :categories_by_taxonomy
      methods << :translated_categories

      relationships = options[:relationships] || {}
      relationships.store(:content_type, {})
      relationships.store(:categories, {:include => [:content, :category]})      
  
      super(options.merge({:relationships => relationships, :methods => methods}))

    end 
    
    #
    # Return the categories grouped by taxonomy
    #
    # @return [Hash] The key is the taxonomy id and the value is an array of terms
    #
    def categories_by_taxonomy

      self.categories.inject({}) do |result, category|
         
        if result.has_key?(category.taxonomy.id.to_sym)
          result[category.taxonomy.id.to_sym] << category
        else
          result[category.taxonomy.id.to_sym] = [category]
        end
        
        result 
      end    

    end

    # ============ Publication interface ===================
    
    #
    # Publication info for the publishing module
    #
    def publication_info

      {:type => :content, :id => id}

    end   

    # ============ Path interface ==========================

    def path
      "/content/#{id}"
    end
 
    # ============ Resource info interface =================
     
    #
    # Get the resource information
    # 
    def resource_info

      "content_#{id}"

    end
    
    private 
    
    #
    # Check the content type
    #
    def check_content_type!

      if self.content_type and (not self.content_type.saved?) and loaded_content_type = ContentType.get(self.content_type.id)
        self.content_type = loaded_content_type
      end

    end
    
    #
    # Check the content publishing workflow
    #
    def check_publishing_workflow!
      self.publishing_workflow = content_type.publishing_workflow
    end

    #
    # Check the content categories
    #
    def check_categories!

     self.categories.map! do |category|
        if (not category.saved?) and loaded_category = Term.get(category.id)
          loaded_category
        else
          category
        end
     end

    end
    
  end #Content 
  
end #ContentManagerSystem

