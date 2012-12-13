require 'data_mapper' if not defined?(DataMapper)
require 'ysd-plugins' unless defined?Plugins::AspectConfiguration

module ContentManagerSystem

  #
  # Content type aspects 
  # They represent the aspects that have been configured for the content type
  #
  class ContentTypeAspect
    include DataMapper::Resource
    include ::Plugins::AspectConfiguration
    
    storage_names[:default] = 'cms_content_type_aspects'
    
    belongs_to :content_type, 'ContentManagerSystem::ContentType', :child_key => [:content_type_id], :parent_key => [:id], :key => true
    property :aspect, String, :length => 32, :field => 'aspect', :key => true, :index => true, :unique_index => false

    alias old_save save
    
    #
    # Saves thec content type aspect
    #
    def save
      
      if self.content_type and not self.content_type.saved?
        attributes = self.content_type.attributes.clone
        attributes.delete(:id)
        self.content_type = ContentType.first_or_create({:id => self.content_type.id}, attributes ) 
      end
        
      old_save
    
    end
    
    #
    # Gets the variable name which stores the param value for the entity/aspect
    #
    def get_variable_name(attribute_id)
     
      "aspect.#{aspect}.ct.#{content_type.id}.#{attribute_id}"
     
    end
    
    #
    # Gets the module name
    #
    def get_module_name
    
      return :cms
    
    end    

    #
    # Generates the json
    #
    def as_json(options={})

      methods = options[:methods] || []
      methods << :aspect_attributes

      options[:methods] = methods
      
      super(options)

    end    

     
  end
end