require "ysd_md_translation_cms_content"

module ContentManagerSystem
  
  #
  # Reopen the class to extend with the content translation
  #
  module ContentTranslation
  
    attr_accessor :language_code
  
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
    
      if content_translation = ::ContentManagerSystem::Translation::ContentTranslation.get(key)
        translated_attributes = {}
        content_translation.get_translated_attributes(language_code).each {|term| translated_attributes.store(term.concept.to_sym, term.translated_text)}
        content = Content.new(key, attributes.merge(translated_attributes){ |key, old_value, new_value| new_value.to_s.strip.length > 0?new_value:old_value }) 
      else
        content = self       
      end
      
      content.language_code = language_code
    
      content
    
    end
  
    #
    # Retrieve the categories (translated)
    #
    def get_translated_categories
        
      if not instance_variable_get(:@full_translated_categories) 
       if language_code
         @full_translated_categories = get_categories.map { |term| term.translate(language_code) }
       else
         @full_translated_categories = get_categories        
       end
      end
      
      @full_translated_categories
    
    end   

  end #Content

end #ContentManagerSystem
