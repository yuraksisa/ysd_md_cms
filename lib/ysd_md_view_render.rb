module Model
  #
  # It represents a view render, that is the way to create a gui representation of the view
  #
  class ViewRender
   
    attr_reader :id, :description, :view_style, :pre_processor, :model_restricted, :models
    
    #
    # Constructor
    #
    # @param [String] The render identifier
    # @param [String] The render description
    # @param [ViewStyle] The view style to which the render applies
    # @param [Proc] preprocessor
    # @param [Boolean] If the render is restricted to some models
    # @param [Array] The ViewModels to which the render can work
    #   
    #
  	def initialize(id, description, view_style, pre_processor=nil, model_restricted=false, models=[])
  	  @id = id
  	  @description = description
  	  @view_style = view_style	
  	  @pre_processor = pre_processor
      @model_restricted = model_restricted
      @models = models
    
      self.class.view_renders << self
    end
    
    #
    # Get a view render by its id
    #
    def self.get(id)
      (view_renders.select { |view_render| view_render.id == id}).first
    end
    
    #
    # Get the view renders which can be applied to a view_style and model
    #
    # @param [ViewStyle] The view style
    # @param [ViewModel] The view model
    #
    def self.all(view_style, model=nil)

      view_renders.select do |view_render|
      	 (view_render.view_style == view_style) and (model.nil? or (not view_render.model_restricted or view_render.models.include?(model)))
      end

    end

    #
    #
    #
    def self.view_renders
      @view_renders ||= []
    end

    #
    # Get a json representation of the 
    #
    def to_json(*args)
      
      {:id => id, :description => description, :view_style => view_style}.to_json
      
    end      

  end #ViewRender
end