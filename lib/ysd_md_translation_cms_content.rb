require 'data_mapper' unless defined?DataMapper
require 'ysd_md_translation' unless defined?Model::Translation::Translation

module ContentManagerSystem
  module Translation
      #
      # Content Translation
      #  
      # It represents the translation of a content
      #
      class ContentTranslation
        include ::DataMapper::Resource
      
        storage_names[:default] = 'trans_content_translation'
        
        belongs_to :content, 'ContentManagerSystem::Content', :parent_key => [:id], :child_key => [:content_id], :key => true
        belongs_to :translation, 'Model::Translation::Translation', :child_key => [:translation_id], :parent_key => [:id]
        
        def destroy
          transaction do
            super
            translation.destroy
          end
        end

        #
        # Creates or updates the content translation
        #
        def self.create_or_update(content_id, language_code, attributes)
        
          content_translation = nil
          
          ContentTranslation.transaction do 
         
            content_translation = ContentTranslation.get(content_id)                  
          
            if content_translation
              content_translation.set_translated_attributes(language_code, attributes)
            else
              translation = Model::Translation::Translation.create_with_terms(language_code, attributes) 
              content_translation = ContentTranslation.create({:content => ContentManagerSystem::Content.get(content_id), :translation => translation})
            end
            
          end
          
          content_translation
        
        end
        
        #
        # Find the content translated attributes 
        #
        # @param [String] language_code
        #  The language
        #
        # @return [Array]
        #  An array of TranslationTerm which contains the translated terms associated to the content
        #
        #
        def get_translated_attributes(language_code)
        
          Model::Translation::TranslationTerm.find_translations_by_language(translation.id, language_code)
        
        end
        
        #
        # Updates the translated attributes
        #
        # @param [String] language_code
        #  The language
        #
        # @param [Hash] attributes
        #  The attributes with the translations
        #
        #
        def set_translated_attributes(language_code, attributes)
        
          translation.update_terms(language_code, attributes)
        
        end
        
      end #ContentTranslation

  end #Translation
end #Model
