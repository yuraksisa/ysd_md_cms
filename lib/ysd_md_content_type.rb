require 'data_mapper' if not defined?(DataMapper)
require 'ysd-plugins' unless defined?Plugins::Plugin

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
    has n, :usergroups, 'ContentTypeUserGroup', :child_key => [:content_type_id], :parent_key => [:id], :constraint => :destroy
    
    alias old_save save
    before :destroy, :check_before_destroy

    #
    # Override the save method to ensure saving aspects and usergroups
    #
    def save
     
      old_save

      update_aspects
      update_usergroups

    end
    
    #
    # Overwritten to store the assgined aspects
    #
    def attribute_set(name, value) 
      if (name.to_sym == :aspects)
        @assigned_aspects = value
      else
        if (name.to_sym == :usergroups)
          @assigned_usergroups = value
        else
          super(name, value)
        end
      end
    end
   
    #
    # Overwritten to store the assigned aspects
    #
    def attributes=(attributes)
      @assigned_aspects = attributes.delete('aspects')
      @assigned_usergroups = attributes.delete('usergroups')
      super(attributes)
    end

    #
    # Exporting to json
    #
    def as_json(options={})
    
      # Export the aspects and usergropus relationships

      relationships = options[:relationships] || {}
      relationships.store(:aspects, {:include => [:aspect, :content_type]})
      relationships.store(:usergroups, {:include => [:usergroup, :content_type]})

      super(options.merge({:relationships => relationships}))
    
    end
        
    #
    # Get the aspects applied to the content type
    #
    # @return [:Plugins::Aspect]
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
    
    #
    # Assign usergroups to the content type
    #
    def assign_usergroups(assigned_usergroups)
        
        the_assigned_usergroups = assigned_usergroups.map { |ct_usergroup| ct_usergroup['usergroup']['group']  }

        remove_usergroups = ContentTypeUserGroup.all('content_type.id' => id, 
                                                     'usergroup.group.not' => the_assigned_usergroups )
        
        # remove not existing aspects
        if remove_usergroups
          remove_usergroups.destroy      
        end
        
        # add new aspects
        assigned_usergroups.each do |ct_usergroup|
          if not ContentTypeUserGroup.get(ct_usergroup['content_type']['id'], ct_usergroup['usergroup']['group'])
            ContentTypeUserGroup.create(ct_usergroup)
          end
        end
            
        usergroups.reload
    
    end    
    
    private
     
    #
    # Check the content type before destroying it
    #
    def check_before_destroy

      #check that there aren't documents of the type
      if Content.all({:limit => 1, :offset => 0}).length > 0
        throw :halt
      end

    end

    #
    # Update aspects
    #    
    def update_aspects
      
      if @assigned_aspects
        assign_aspects(@assigned_aspects)
      end
          
    end
    
    #
    # Update usergroups
    #
    def update_usergroups
      puts "updating usergroups #{@assigned_usergroups}"
      if @assigned_usergroups
        assign_usergroups(@assigned_usergroups)
      end
    end

  end #ContentType
end #ContentManagerSystem