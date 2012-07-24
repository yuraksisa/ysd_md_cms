require 'ysd-persistence' 
require 'uuid'
require 'base64'
require 'ysd_md_auditory' if not defined?Auditory
require 'ysd-md-profile' if not defined?Users
module ContentManagerSystem

  # -------------------------------------
  # It represents a content
  # -------------------------------------
  class Content
    include Persistence::Resource
    include Users::ResourceAccessControlPersistence # Extends the model to control its access
    include Audit::AuditorPersistence               # Extends the model to add audit information
    
    property :alias         # An URL alias to the content
    property :title         # The content title
    property :subtitle      # The content subtitle
    property :description   # The content description
    property :summary       # The content summary
    property :keywords      # The key words (important words)
          
    property :type          # The content type (it must exist the ContentManagerSystem::ContentType)
    property :categories    # The content category (an array of ContentManagerSystem::Term)
    property :categories_by_taxonomy # The categories organized by taxonomy
    
    property :language      # The language in which the content has been written
    
    property :author        # The content author

    property :body          # The content

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
    
      limit = options[:limit] || 10
      offset = options[:offset] || 0
      count = options[:count] || true
    
      result = []
      
      result << Content.all({:limit => limit, :offset => offset, :order => [['creation_date','desc']]})
      
      if count
        result << Content.count
      end
      
      if result.length == 1
        result = result.first
      end
      
      result
              
    end
    
    #
    # Retrieve the contents which belong to a category
    # 
    # @param [String] term_id
    #  The term id
    #
    def self.find_by_term(term_id)
        
      #result = Content.all({:conditions => {:categories => [term_id.to_i]}, :order => [['creation_date','desc']]})
      
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
      
      # creates the ID
      key ||= UUID.generator.generate(:compact)
          
      # creates the alias
           
      content = Content.new(key, options)      
      content.attribute_set(:alias, File.join(content.type, Time.now.strftime('%Y%m%d') , content.title.downcase.gsub(/\s/,'-')))
      
      content.create
      
      content
    
    end
    
    # ============== Instance methods =====================
    
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

