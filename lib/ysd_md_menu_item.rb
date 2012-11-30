require 'data_mapper' unless defined?(DataMapper)
require 'ysd_md_menu_item_translation'

module Site
  #
  # It represents a menu item
  #
  class MenuItem
    include DataMapper::Resource
    include ContentManagerSystem::MenuItemTranslation # Extends the menu item to manage translations

    storage_names[:default] = "site_menu_items"
    
    property :id, Serial, :field => 'id', :key => true                       # The menu item id
    
    property :title, String, :field => 'title', :length => 80                # The menu item title : It's used to define the link text
    property :link_route, String, :field => 'route', :length => 128          # The menu item link : It's used to define the link url
    property :description, String, :field => 'description', :length => 256   # The menu item description
    property :module, String, :field => 'module', :length => 64              # The module which defines the menu item
    property :weight, Integer, :field => 'weight', :default => 0             # The menu item weight (to order all the options)
    
    belongs_to :menu, 'Site::Menu', :child_key => [:menu_name] , :parent_key => [:name] # The menu which defines the menu item
    
    belongs_to :parent, 'Site::MenuItem', :child_key => [:parent_id], :parent_key => [:id], :required => false # The parent menu item
    has n,   :children, 'Site::MenuItem', :child_key => [:parent_id], :parent_key => [:id] # The children menu items     
  
    alias old_save save
    
    def save
    
      if self.menu and not self.menu.saved?
        self.menu = Menu.get(self.menu.name)        
      end
      
      if self.parent and not self.parent.saved?
        self.parent = MenuItem.get(self.parent.id)
      end
    
      old_save
    
    end
  
  end #Menu
end #Site