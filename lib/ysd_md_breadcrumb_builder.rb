module Site
  #
  # This is the standard breadcrumb builder. 
  # It constructs the breadcrumb from the routes
  #
  class BreadcrumbBuilder
   
    #
    # @params [String] path
    #  The url path that is being processed
    # @params [Hash] context
    # 
    def self.build(path, context)
      
      app = context[:app]

      breadcrumb = Breadcrumb.new
      
      route = Routes.instance.get(path) 

      #p "route: #{route.inspect}"

      while route  
        breadcrumb.unshift({:path => route.path, :title => route.title})
        route = route.parent      
      end

      # Removes the last element (which is the actual page)
      #breadcrumb.pop 
      
      # Adds the home element
      #breadcrumb.unshift({:path => '/', :title => app.t.breadcrumb.home})
      
      #p "breadcrumb: #{breadcrumb}"

      return breadcrumb
    
    end
  
  end
end