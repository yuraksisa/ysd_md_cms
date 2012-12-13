require 'data_mapper' if not defined?(DataMapper)
require 'ysd-plugins' unless defined?Plugins::Plugin
require 'ysd_md_publishing_workflow'

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
    property :publishing_workflow, String, :field => 'publishing_workflow', :length => 20   # The publication workflow

    property :message_on_new_content, Text, :field => 'message_on_new_content'
    property :message_on_edit_content, Text, :field => 'message_on_edit_content'

    has n, :aspects, 'ContentTypeAspect', :child_key => [:content_type_id], :parent_key => [:id], :constraint => :destroy, :order => [:weight.asc]
    has n, :usergroups, 'ContentTypeUserGroup', :child_key => [:content_type_id], :parent_key => [:id], :constraint => :destroy
    
    alias old_save save
    before :destroy, :check_before_destroy

    #
    # Override the save method to ensure saving aspects and usergroups
    #
    def save
     
      transaction do |transaction|
        old_save
        update_aspects
        update_usergroups
        transaction.commit
      end

    end

    #
    # Check if the content type can be created by an user
    #
    def can_be_created_by?(user)
      
      user.usergroups.any? {usergroups.map {|ctug| ctug.usergroup.group}}

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
    
    # ------------- Aspects management --------------

    #
    # Return the model applicable aspects
    #
    # @return [Array] of Plugin::Aspect
    #
    def applicable_aspects
      
      Plugins::Aspect.all.select do |aspect| 
        Plugins::ModelAspect.aspects_applicable(ContentManagerSystem::Content).include?(aspect.model_aspect)
      end

    end

    #
    # Get a concrete aspects associated to the resource (::Model::EntityAspect)
    #
    # @return [Plugins::AspectConfiguration]
    #
    def aspect(aspect)

      (aspects.select { |ct_aspect| ct_aspect.aspect == aspect }).first

    end

    #
    # Assign aspects to the content type
    #
    def assign_aspects(assigned_aspects)
        
        the_assigned_aspects = assigned_aspects.map { |ct_aspect| ct_aspect['aspect']  }
        
        removed_aspects = ContentTypeAspect.all({'content_type_id' => id, 
                                                 :aspect.not => the_assigned_aspects} )
         
        # remove not existing aspects
        if removed_aspects and removed_aspects.length > 0
          removed_aspects.destroy      
        end
        
        # add new aspects or update the existing ones
        assigned_aspects.each do |ct_aspect|
          if ctype_aspect = ContentTypeAspect.get(ct_aspect['aspect'], ct_aspect['content_type']['id'])
            ctype_aspect.attributes= ct_aspect 
            ctype_aspect.save
          else
            ContentTypeAspect.create(ct_aspect)
          end
        end
            
        aspects.reload
    
    end
    
    # --------------- Usergroups management --------------------

    #
    # Assign usergroups to the content type
    #
    def assign_usergroups(assigned_usergroups)
        
        the_assigned_usergroups = assigned_usergroups.map { |ct_usergroup| ct_usergroup['usergroup']['group']  }

        remove_usergroups = ContentTypeUserGroup.all('content_type_id' => id, 
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
    
    # ------------- Work flow ---------------------------------

    #
    # Get the publishing workflow
    #
    def get_publishing_workflow

      @the_workflow ||= PublishingWorkflow.get(publishing_workflow)

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
      if @assigned_usergroups
        assign_usergroups(@assigned_usergroups)
      end
    end

  end #ContentType
end #ContentManagerSystem