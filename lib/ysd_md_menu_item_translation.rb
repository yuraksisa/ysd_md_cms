require 'ysd_md_translation_cms_menu_item'

module ContentManagerSystem

  #
  # MenuItem
  #
  # Open the Site::MenuItem class to add the translate method which is used to retrieve a translated version
  # of the MenuItem instance
  #
  module MenuItemTranslation
  
    #
    # Translate the menu item into the language code
    #
    # @param [String] language_code
    #  The language ISO 639-1 code
    #
    # @return [Site::MenuItem]
    #  A new instance of Site::MenuItem with the translated attributes
    #
    def translate(language_code)
      
      menu_item = nil
    
      if menu_item_translation = ContentManagerSystem::Translation::MenuItemTranslation.get(id)
        translated_attributes = {}
        menu_item_translation.get_translated_attributes(language_code).each {|term| translated_attributes.store(term.concept.to_sym, term.translated_text)}
        menu_item = ::Site::MenuItem.new(attributes.merge(translated_attributes){ |key, old_value, new_value| new_value.to_s.strip.length > 0?new_value:old_value })
        children.each { |menu_item_child| menu_item.children << menu_item_child }
      else
        menu_item = self       
      end
    
      return menu_item
    
    end
  
  end
end