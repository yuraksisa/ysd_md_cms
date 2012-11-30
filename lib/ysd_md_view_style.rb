# encoding: utf-8
module Model
  #
  # It defines, with the view render, how the view is built
  #
  # There are two view styles:
  #
  #   - teaser : It uses a predefined template 
  #   - fields : It uses a field selection to render the view
  #	
  class ViewStyle

    attr_reader :id, :description
    
    private_class_method :new

    def initialize(id, description)
      @id = id
      @description = description

      self.class.view_styles << self
    end
    
    #
    # Get a view style by its id
    #
    def self.get(id)
      (view_styles.select {|view_style| view_style.id == id}).first
    end
    
    #
    # Gets all the view styles
    #
    def self.all
      view_styles
    end
    
    def self.view_styles
      @view_styles ||= []
    end

    #
    # Get a json representation of the 
    #
    def to_json(*args)
      
      {:id => id, :description => description}.to_json
      
    end  

    VIEW_STYLE_TEASER = new(:teaser, 'Vista predefinida')
    VIEW_STYLE_FIELDS = new(:fields, 'Selección de campos del modelo a mostrar')

  end #ViewStyle
end #Model