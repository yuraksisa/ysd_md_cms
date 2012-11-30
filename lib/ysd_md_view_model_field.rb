module Model
  #
  # It describes an entity field
  #
  class ViewModelField
    
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