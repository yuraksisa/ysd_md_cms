require 'singleton'
module Site
  #
  # It manages all the routes
  #
  class Routes
    include Singleton
    
    def initialize
      
      @lock = Mutex.new
      
      unless instance_variable_defined?(:@routes)
      
        @lock.synchronize do          
          @routes = load_routes(nil) unless instance_variable_defined?(:@routes) 
        end
    
      end      
            
    end
    
    # Retrieve the routes
    #
    # @param  [Hash]
    #   Context
    #
    # @return [Array]
    #   All the defined routes
    #
    def get_all
    
      @routes.values
          
    end

    #    
    # Retrieve the route which matches the path
    #
    # @param [String]
    #   The path to match
    #
    # @return [RouteDefinition]
    #   The definition that better fits the path
    #
    def get(path)
        
      candidates = []
      
      @routes.each do |route_path, route|

          candidates.push(route) if route.regular_expression.match(path) 
        
      end
      
      (candidates.sort!{ |x,y| x.fit <=> y.fit }).last
    
    end
    
    private
    
    #
    # Loads all the routes
    #    
    def load_routes(context)
    
       routes = {}      
       
       modules_routes = Plugins::Plugin.plugin_invoke_all('routes', context)
       modules_routes.each do |module_route|
         parent = if module_route.has_key?(:parent_path)
                    if routes.has_key?(module_route[:parent_path])
                      routes.fetch(module_route[:parent_path])
                    else
                      nil
                    end
                  else
                    nil
                  end
         route = RouteDefinition.new(module_route.merge({:parent => parent}))
         routes.store(route.path, route)        
       end      
       
       routes
    
    end
        
  end #Route
  
  #
  # It represents a route definition
  #
  class RouteDefinition
  
    attr_reader :path, :regular_expression, :parent, :title, :description, :fit, :module
  
    def initialize(options)
  
     @path        = options[:path]
     @regular_expression = options[:regular_expression]
     @parent      = options[:parent]
     @title       = options[:title] 
     @description = options[:description]
     @fit         = options[:fit]
     @module      = options[:module]
    
    end
  
  end
  
end #Site