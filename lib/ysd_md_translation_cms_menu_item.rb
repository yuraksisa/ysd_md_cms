require 'data_mapper' unless defined?DataMapper
require 'ysd_md_translation' unless defined?Model::Translation::Translation

module ContentManagerSystem
  module Translation
      #
      # Menu item translation
      #
      class MenuItemTranslation
        include ::DataMapper::Resource
        
        storage_names[:default] = 'trans_menuitem_translation'

        belongs_to :menu_item, 'Site::MenuItem', :child_key => [:menu_item_id], :parent_key => [:id], :key => true
        belongs_to :translation, 'Model::Translation::Translation', :child_key => [:translation_id], :parent_key => [:id]
      
        #
        # Creates or updates a menu item translation
        #
        # @param [Integer] menu_item_id
        # @param [String]  language_code
        # @param [Hash]    attributes to be translated
        #
        # @return [Model::Translation::Site::MenuItemTranslation]
        #
        def self.create_or_update(menu_item_id, language_code, attributes)
        
          menu_item_translation = nil
        
          MenuItemTranslation.transaction do 
            
            menu_item_translation = MenuItemTranslation.get(menu_item_id)
          
            if menu_item_translation
              menu_item_translation.set_translated_attributes(language_code, attributes)
            else
              translation = Model::Translation::Translation.create_with_terms(language_code, attributes) 
              menu_item_translation = MenuItemTranslation.create({:menu_item => ::Site::MenuItem.get(menu_item_id), :translation => translation})
            end
            
          end      
          
          menu_item_translation
        
        end
      
        #
        # Find the menu item translated attributes
        #
        def get_translated_attributes(language_code)
        
          Model::Translation::TranslationTerm.find_translations_by_language(translation.id, language_code)
        
        end      

        #
        # Updates the translated attributes
        #
        # @param [Numeric] menu_id
        #  The menu id
        #
        # @param [String] language_code
        #  The language code
        #
        # @param [Hash] attributes
        #  The attributes
        #        
        def set_translated_attributes(language_code, attributes)
        
           translation.update_terms(language_code, attributes)
        
        end
      
      
      end #MenuItemTranslation
  end #Translation
end #Model
