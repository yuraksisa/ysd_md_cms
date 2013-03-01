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
    property :publishing_workflow_id, String, :field => 'publishing_workflow_id', :length => 20   # The publication workflow

    property :message_on_new_content, Text, :field => 'message_on_new_content'
    property :message_on_edit_content, Text, :field => 'message_on_edit_content'
    
    property :display, String, :field => 'display', :length => 40 # Display to render the content
    property :template, Text, :field => 'template' # Template for creating content
    property :max_length, Integer, :field => 'max_length', :default => 0 # Content max length

    has n, :aspects, 'ContentTypeAspect', :child_key => [:content_type_id], :parent_key => [:id], :constraint => :destroy, :order => [:weight.asc]

    has n, :content_type_user_groups, 'ContentTypeUserGroup', :child_key => [:content_type_id], :parent_key => [:id], :constraint => :destroy
    has n, :usergroups, 'Users::Group', :through => :content_type_user_groups, :via => :usergroup
    
    alias old_save save

    before :destroy, :check_before_destroy

    #
    # Override the save method to ensure saving aspects and usergroups
    #
    def save
     
      transaction do |transaction|
        check_usergroups! if self.usergroups and (not self.usergroups.empty?)
        old_save
        update_aspects
        transaction.commit
      end

    end

    #
    # Check if the content type can be created by an user
    #
    def can_be_created_by?(user)
      
      not (user.usergroups & usergroups).empty?

    end
    
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
      @assigned_aspects = attributes.delete(:aspects)
      super(attributes)
    end

    #
    # Exporting to json
    #
    def as_json(options={})
 
      relationships = options[:relationships] || {}
      relationships.store(:aspects, {:include => [:aspect, :content_type]})
      relationships.store(:usergroups, {})

      super(options.merge({:relationships => relationships}))
    
    end
    
    # ------------- Aspect entity interface --------------

    #
    # Retrieve the aspects that can be applied to a content type
    #
    # @return [Array] of Plugin::Aspect
    #
    def applicable_aspects      
      Plugins::Aspect.all.select do |aspect| 
        Plugins::ModelAspect.aspects_applicable(ContentManagerSystem::Content).include?(aspect.model_aspect)
      end
    end

    #
    # Get the aspect associated to the content type
    #
    # @param [String] The aspect identifier
    #
    # @return [Plugins::AspectConfiguration]
    #
    def aspect(aspect)
      (aspects.select { |content_type_aspect| content_type_aspect.aspect == aspect }).first
    end

    # ------------ Aspects management ---------------

    #
    # Assign aspects to the content type
    #
    def assign_aspects(assigned_aspects)
        
        the_assigned_aspects = assigned_aspects.map { |content_type_aspect| content_type_aspect[:aspect]  }

        # remove non existing aspects
        removed_aspects = ContentTypeAspect.all({:content_type => {:id => id}, 
                                                 :aspect.not => the_assigned_aspects} )
        if removed_aspects and removed_aspects.length > 0
          removed_aspects.destroy      
        end
        
        # add new aspects or update the existing ones
        assigned_aspects.each do |content_type_aspect|
          content_type_aspect[:content_type] = {:id => id}
          content_type_aspect.delete(:aspect_attributes)
          if ctype_aspect = ContentTypeAspect.get(content_type_aspect[:aspect], id)
            ctype_aspect.attributes= content_type_aspect 
            ctype_aspect.save
          else
            ContentTypeAspect.create(content_type_aspect)
          end
        end
            
        aspects.reload

    end
       
    
    # ------------- Workflow ---------------------------------

    #
    # Get the publishing workflow
    #
    def publishing_workflow

      @the_workflow ||= PublishingWorkflow.get(publishing_workflow_id)

    end

    private
    
    def check_usergroups!

      self.usergroups.map! do |ug|
        if (not ug.saved?) and loaded_usergroup = Users::Group.get(ug.group)
          loaded_usergroup
        else
          ug
        end 
      end

    end

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
    

  end #ContentType
end #ContentManagerSystem