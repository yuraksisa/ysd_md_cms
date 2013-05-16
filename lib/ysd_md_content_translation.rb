require "ysd_md_translation_cms_content"

module ContentManagerSystem
  
  #
  # Reopen the class to extend with the content translation
  #
  # The language code must be defined in TranslationLanguages
  #
  module ContentTranslation
  
    attr_accessor :language_code

    def self.included(model)

      if model.respond_to?(:has)
        model.has 1, :content_translation, 'ContentManagerSystem::Translation::ContentTranslation', :constraint => :destroy
      end

    end
  
    #
    # Translate the content into the language code
    #
    # @param [String] language_code
    #  The language ISO 639-1 code
    #
    # @return [Content]
    #  A new instance of ContentManagerSystem::Content with the translated attributes
    #
    def translate(language_code)
      
      content = nil
    
      if content_translation = ::ContentManagerSystem::Translation::ContentTranslation.get(id)
        
        translated_attributes = {}
        
        content_translation.get_translated_attributes(language_code).each do |term| 
          translated_attributes.store(term.concept.to_sym, term.translated_text)
        end

        content = Content.new(attributes.merge(translated_attributes){ |key, old_value, new_value| new_value.to_s.strip.length > 0?new_value:old_value }) 
      else
        content = self       
      end
      
      content.language_code = language_code
    
      content
    
    end
  
    #
    # Retrieve the categories (translated)
    #
    def translated_categories
        
      if not instance_variable_get(:@full_translated_categories) 
       if language_code
         @full_translated_categories = categories.map { |term| term.translate(language_code) }
       else
         @full_translated_categories = categories        
       end
      end
      
      @full_translated_categories
    
    end   

  end #Content

end #ContentManagerSystem
