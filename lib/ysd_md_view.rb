require 'dm-types'
require 'data_mapper' 
require 'ysd-persistence' if not defined?(Persistence)

#
# DataMapper.setup(:default, {:adapter => 'yaml', :path => '/Users/jgil/proyectos/yurak.sisa/implementacion/data'})
# Persistence.setup(:default, { :adapter => 'mongodb', :host => 'staff.mongohq.com', :port => '10049', :database => 'yurak_sisa', :username => 'yurak.sisa', :password => 'joanic2002' })
# Persistence.setup(:memory, {:adapter=>'memory'})
# Persistence.repository(:memory) do ResourceLoader.instance.load_files(ContentManagerSystem::Content, File.join('/Users/jgil/proyectos/yurak.sisa/implementacion','content')) end
#
#
module ContentManagerSystem

  # It represents a view of data
  # 
  #
  class View
    include DataMapper::Resource
    
    storage_names[:default] = 'cms_views'
    
    property :view_name, String, :field => 'view_name', :length => 32, :key => true
    property :model_name, String, :field => 'model_name', :length => 256
    property :description, String, :field => 'description', :length => 256
    property :query_fields, Json, :field => 'query_fields'
    property :query_conditions, Json, :field => 'query_conditions'
    property :query_order, Json, :field => 'query_order'
    property :query_info, Json, :field => 'query_info' 
    property :type, String, :field => 'type', :length =>10
    property :data_repository, String, :field => 'data_repository', :length => 32, :default => 'default' 
    
        
    # Retrieves data from the data_repository
    #
    # @param [String] arguments
    #   A string which represents the query arguments, separated by an slash
    #   Example:
    #     /param1/param2
    #     There are two parameters, param1 and param2   
    #
    # @return [Array]
    #   The data that matches the query
    #
    def get_data(arguments="")
                        
      the_model = (Persistence::Model.descendants.select do |model| model_name == model.model_name.downcase end).first      
      
      unless the_model
        puts "The model is not defined. Has you require it?"
      end
      
      # Build the query  
      
      #Apply args to the conditions
      arguments ||= ''
      args_array = arguments.split("/")
      args_array.delete('')
      the_query_conditions = {}
      self.query_conditions.each do |key, value|
        if value.kind_of?(String)
          the_query_conditions[key] = value.to_s % args_array
        else
          the_query_conditions[key] = value
        end
      end
      puts "the_query_conditions : #{the_query_conditions.to_json}"
      
      #context conditions
                    
      query = {:fields => self.query_fields, :conditions => the_query_conditions, :order => self.query_order}
              
      puts "query : #{query.to_json}"       
      
      # Executes the query
      
      Persistence.repository(data_repository) do 
      
        (the_model)?the_model.all(query):[]     
        
      end   
    
    end
        
  end #View
end #ContentManagerSystem