require 'ysd-persistence' 
require 'uuid'
require 'base64'
require 'unicode_utils' unless defined?UnicodeUtils
require 'ysd-plugins' unless defined?Plugins::ApplicableModelAspect
require 'ysd_md_audit' unless defined?Audit::AuditorPersistence
require 'ysd_md_rac' unless defined?Users::ResourceAccessControlPersistence
require 'support/ysd_md_cms_support' unless defined?ContentManagerSystem::Support
require 'aspects/ysd-plugins_applicable_model_aspect' unless defined?Plugins::ApplicableModelAspect
require 'ysd_md_state'

module ContentManagerSystem

  # -------------------------------------
  # It represents a content
  # -------------------------------------
  class Content
    include Persistence::Resource
    extend  Plugins::ApplicableModelAspect           # Extends the entity to allow apply aspects
    include Users::ResourceAccessControl             # Extends the model to Resource Access Control
    include Audit::Auditor                           # Extends the model to Audit
    include ContentManagerSystem::Publishable        # Extends the model to manage publication
       
    extend ::ContentManagerSystem::Support::ContentExtractor # Content extractor
    
    property :alias, String           # An URL alias to the content
   
    property :title, String           # The content title
    property :subtitle, String        # The content subtitle
    property :description, String     # The content description
    property :summary, String         # The content summary
    property :keywords, String        # The key words (important words)
    property :language, String        # The language in which the content has been written
    property :author, String          # The content author

    property :type, String                    # The content type (it must exist the ContentManagerSystem::ContentType)
    property :categories, Object              # The content category (an array of ContentManagerSystem::Term)
    property :categories_by_taxonomy, Object  # The categories organized by taxonomy

    property :body, String            # The content

    # ========================= Finders ===========================
    
    #
    # @param [Hash] options
    #   
    #   :limit
    #   :offset
    #   :count
    #
    # @return [Array]
    #
    #   Instances of ContentManagerSystem::Content
    #
    def self.find_all(options={})
    
      query_options = {}
      
      query_options.store(:limit, options[:limit] || 10)
      query_options.store(:offset, options[:offset] || 0)
      query_options.store(:order, options[:order] || [['creation_date','desc']])
      query_options.store(:conditions, options[:conditions]) if options.has_key?(:conditions)
      
      count = options[:count] || true

      result = []
    
      result << Content.all(query_options)
      
      if count
        count_conditions = {}
        if query_options.has_key?(:conditions)
          count_conditions.store(:conditions, query_options[:conditions])
        end
        result << Content.count(count_conditions)
      end
      
      if result.length == 1
        result = result.first
      end
      
      result
              
    end
    
    #
    # Retrieve the tagged contents
    # 
    # @param [String] term_id
    #  The term id
    #
    def self.find_by_term(term_id)
      
      Content.all({:conditions => Conditions::Comparison.new(:categories, '$in', [term_id.to_i]), :order => [['creation_date','desc']]})
    
    end    
    
    
    # ======================= Class methods =======================

    #
    # Create a new content
    #
    # @param [Hash] options
    #
    #  Content attributes
    #
    #
    def self.create(*args)
      
      if (args.size == 1)
        options = args.first
      else
        if (args.size == 2)
           key = args.first
           options = args.last
        end
      end
          
      # creates the alias
           
      content = Content.new(key, options) 
      
      if content.alias.strip.length == 0     
        alias_str = UnicodeUtils.nfkd(content.title).gsub(/[^\x00-\x7F]/,'').gsub(/\s/,'-')
        content.attribute_set(:alias, File.join('/', content.type, Time.now.strftime('%Y%m%d') , alias_str))
      end
      
      content.create
      
      return content
    
    end
    
    #
    # Create a content from a file
    #
    # @param [String] the file path
    # @return [ContentManagerSystem::Content] the content
    #
    def self.new_from_file(file_path)
    
      resource_name = File.basename(file_path, File.extname(file_path))
      content = Content.new(resource_name, parse_content_file(file_path))
    
    end
    
    # ============== Instance methods =====================

    def initialize(key, data={})

     key ||= UUID.generator.generate(:compact)
     super(key, data)

    end

    #
    # Overwritten to initialize the publishing workflow when the type is assigned
    #
    def attribute_set(name, value) 
      super(name, value)
      if (name.to_sym == :type)
        if c_type = ContentType.get(value)
          attribute_set(:publishing_workflow, c_type.publishing_workflow)
        end
      end
    end
   
    #
    # Overwritten to initialize the publishing workflow when the type is assigned
    #
    def attributes=(attributes)
      if attributes.has_key?(:type) and (not attributes.has_key?(:publishing_workflow)) and c_type=ContentType.get(attributes[:type])
        attributes.merge!({:publishing_workflow => c_type.publishing_workflow})
      end
      if (not attributes.has_key?(:publishing_state)) and ((publishing_state.nil?) or (publishing_state == ''))
        attributes.merge!({:publishing_state => nil})
      end
      super(attributes)
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
     
        #puts "categories by taxonomy : #{categories_by_taxonomy}"
     
        if categories_by_taxonomy and categories_by_taxonomy.kind_of?Hash    
          categories_by_taxonomy.each do |taxonomy, terms|
            if terms.kind_of?(Array)
              categories_list.concat(terms)   
            else
              categories_list << terms
            end               
          end
        end
        
        #puts "categories list: #{categories_list} #{categories_by_taxonomy} #{categories_by_taxonomy.class.name}"
        
        @full_categories = ContentManagerSystem::Term.all(:id => categories_list)
      
      end
      
      #puts "categories: #{@full_categories}"
      
      @full_categories
     
    end
    
    #
    # Get the content type
    #
    def get_content_type
      
      if type.nil?
        return nil
      end

      @content_type ||= ContentType.get(type)

    end
        
    # ============ Exporting the objects =================
    
    # Serializes the object to json
    #
    # Adds the categories_info
    # 
    def to_json(options={})
 
      data = exportable_attributes
      data.to_json
  
    end 
    
    #
    # Get a hash with the exportable attributes
    #
    def exportable_attributes
            
      data = super
      
      data.store(:key, self.key)
      data.store(:categories_info, self.get_categories)     
    
      data
    
    end
    
    # ============ Publication interface ===================
    
    #
    # Publication info for the publishing module
    #
    def publication_info

      {:type => :content, :id => key}

    end
  
  end #end class Content 
  
end #end module ContentManagerSystem

