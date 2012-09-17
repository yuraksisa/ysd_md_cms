module Model
  
  #
  # It represents the view styles and renders
  #
  class ViewDefinition
    
    #
    # Retrieve the view types
    #
    def self.view_styles(context={})
  
       app = context[:app] 

       [{:id => :teaser, :description => app.t.view_styles.teaser},
        {:id => :fields, :description => app.t.view_styles.fields}] 
    
    end
    
    #
    # Retrieve the view renders depending on the type
    #
    def self.view_renders(view_style)
    
       if (view_style == 'teaser')
         [{:id => :teaser, :description => :teaser}]
       else
         [{:id => :list, :description => :list}, 
          {:id => :table, :description => :table},
          {:id => :div, :description => :div}]
       end
       
    end 
  
  end

  #
  # It describes an entity to create views
  #
  class ViewEntityInfo
  
    attr_reader :view_entity_model, :view_entity_description, :view_entity_model_class, :view_entity_render_template, :view_entity_fields
  
    def initialize(view_entity_model, view_entity_description, view_entity_model_class, view_entity_render_template, view_entity_fields)
    
      @view_entity_model = view_entity_model
      @view_entity_description = view_entity_description
      @view_entity_model_class = view_entity_model_class
      @view_entity_render_template = view_entity_render_template
      @view_entity_fields = view_entity_fields
    
    end
  
    #
    # Get a json representation of the 
    #
    def to_json(*args)
      
      {:view_entity_model => view_entity_model, :view_entity_description => view_entity_description, :view_entity_fields => view_entity_fields}.to_json
      
    end  
  
  end

  #
  # It describes an entity field
  #
  class ViewEntityFieldInfo
    
    attr_reader :field_name, :field_description, :field_type
    
    #
    #
    #
    def initialize(field_name, field_description, field_type)
      @field_name = field_name
      @field_description = field_description
      @field_type = field_type
    end
  
    #
    # Get a json representation of the 
    #
    def to_json(*args)
      
      {:field_name => field_name, :field_description => field_description, :field_type => field_type}.to_json
      
    end  
  
  end
  
end