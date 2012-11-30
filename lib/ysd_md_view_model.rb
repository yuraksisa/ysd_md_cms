module Model

  #
  # It describes an entity(model) to retrieve data when creating views
  #
  class ViewModel
  
    attr_reader :view_entity_model, :view_entity_description, :view_entity_model_class, :view_entity_render_template, :view_entity_fields
  
    def initialize(view_entity_model, view_entity_description, view_entity_model_class, view_entity_render_template, view_entity_fields)
    
      @view_entity_model = view_entity_model
      @view_entity_description = view_entity_description
      @view_entity_model_class = view_entity_model_class
      @view_entity_render_template = view_entity_render_template
      @view_entity_fields = view_entity_fields
    
      self.class.view_models << self

    end
  
    #
    # Get a json representation of the 
    #
    def to_json(*args)
      
      {:view_entity_model => view_entity_model, :view_entity_description => view_entity_description, :view_entity_fields => view_entity_fields}.to_json
      
    end  
    
    #
    # Get a view model by its id
    #
    def self.get(view_entity_model)
      (view_models.select { |view_model| view_model.view_entity_model == view_entity_model.to_sym}).first
    end
    
    #
    # Get all defined view models
    #
    def self.all
      view_models
    end

    def self.view_models
      @view_models ||= []
    end

  end #ViewModel
end	#ViewModel
