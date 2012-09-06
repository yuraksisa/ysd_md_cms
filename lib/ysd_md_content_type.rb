require 'data_mapper' if not defined?(DataMapper)

#
module ContentManagerSystem

  #
  # It represents a content type 
  #
  class ContentType
    include DataMapper::Resource

    storage_names[:default] = 'cms_content_types'

    property :id, String, :field => 'id', :length => 20, :key => true    
    property :name, String, :field => 'name', :length => 50
    property :description, String, :field => 'description', :length => 256

    has n, :aspects, 'ContentTypeAspect', :child_key => [:content_type_id], :parent_key => [:id], :constraint => :destroy
    
    #
    # Overwritten to store the assgined aspects
    #
    def attribute_set(name, value) 
      if (name.to_sym == :aspects)
        @assigned_aspects = value
      else
        super(name, value)
      end
    end
   
    #
    # Overwritten to store the assigned aspects
    #
    def attributes=(attributes)
    
      @assigned_aspects = attributes.delete('aspects')
      super(attributes)
    
    end

    before :update do |content_type|
      update_aspects
    end
        
    #
    # Get the aspects applied to the content type
    #
    def get_aspects(context)
      
      aspects_ids = aspects.map do |ct_aspect|
                      ct_aspect.aspect.to_sym
                    end
           
      ct_aspects = Plugins::Plugin.plugin_invoke_all('aspects', context).select do |aspect|
        aspects_ids.include?(aspect.id)
      end
      
      return ct_aspects
      
    end
    
    #
    # Get a concrete aspects associated to the resource (::Model::EntityAspect)
    #
    # @return [::ContentManagerSystem::ContentTypeAspect]
    #
    def aspect(aspect)

      (aspects.select { |ct_aspect| ct_aspect.aspect == aspect }).first
    
    end

    #
    # Exporting to json
    #
    def as_json(options={})
    
      relationships = options[:relationships] || {}
      relationships.store(:aspects, {:include => [:aspect, :content_type]})
     
      super(options.merge({:relationships => relationships}))
    
    end
    
    #
    # Assign aspects to the content type
    #
    def assign_aspects(assigned_aspects)
        
        the_assigned_aspects = assigned_aspects.map { |ct_aspect| ct_aspect['aspect']  }
        
        remove_aspects = ContentTypeAspect.all(:content_type => {:id => id}, 
                                               :aspect.not => the_assigned_aspects )
         
        # remove not existing aspects
        if remove_aspects
          remove_aspects.destroy      
        end
        
        # add new aspects
        assigned_aspects.each do |ct_aspect|
          if not ContentTypeAspect.get(ct_aspect['aspect'], ct_aspect['content_type']['id'])
            ContentTypeAspect.create(ct_aspect)
          end
        end
            
        aspects.reload
    
    end
    
    private
    
    #
    # Update aspects
    #    
    def update_aspects
      
      if @assigned_aspects
        assign_aspects(@assigned_aspects)
      end
          
    end

  end #ContentType
end