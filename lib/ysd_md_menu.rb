require 'data_mapper' unless defined?(DataMapper)
module Site
  #
  # It represents a menu
  #
  class Menu
    include DataMapper::Resource
  
    storage_names[:default] = "site_menus"
    
    property :name, String, :field => 'name', :length => 32, :key => true
    property :title, String, :field => 'title', :length => 80
    property :description, String, :field => 'description', :length => 256
  
    has n, :menu_items, 'Site::MenuItem', :child_key => [:menu_name], :parent_key => [:name]
    
    #
    # Retrieve the root menu items
    #
    def root_menu_items
    
      menu_items.select do |menu_item|
        menu_item.parent.nil?
      end
    
    end
    
    #
    # Build a menu
    #
    # @param [Hash] options
    #
    #   The menu attributes, that is:
    #
    #     :name        The menu name
    #     :title       The menu title
    #     :description The menu description
    #
    # @param [Hash] menu_definition
    #
    #   The menu items, that is, an Array of Hash which the following structure
    #
    #     :path        The menu path (which defines the deep)
    #     :options     A hash which defines the menu item
    #
    def self.build(options, menu_definition)

      path_extractor    = /(.+)?\/(.+)$/
      menu_items_holder = {}   

      menu = Menu.new(options)
 
      # Sort the menu_definition by its path
      menu_definition.sort! { |x,y| x[:path] <=> y[:path] }
      
      # Creates the menu items
      menu_definition.each do |item|
        path = item[:path]
        menu_item = MenuItem.new(item[:options].merge({:menu => menu}))
        parent_menu = if (path_parts = path.match(path_extractor))
                        parent  = path_parts[1]          
                        menu_items_holder.fetch(parent) unless parent.nil?           
                      end        
                           
        if parent_menu
          menu_item.parent = parent_menu
          parent_menu.children << menu_item
        end
                  
        menu.menu_items << menu_item
                                
        menu_items_holder.store(path, menu_item)
      
      end
    
      menu
    
    end
  
  end #Menu
end #Site