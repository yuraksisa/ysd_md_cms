require "ysd_md_translation_cms_content"

module ContentManagerSystem
  
  #
  # Reopen the class to extend with the template translation
  #
  # The language code must be defined in TranslationLanguages
  #
  module TemplateTranslation
  
    attr_accessor :language_code

    def self.included(model)

      if model.respond_to?(:has)
        model.has 1, :template_translation, 'ContentManagerSystem::Translation::TemplateTranslation', :constraint => :destroy
      end

    end

    #
    # Translate the template into the language code
    #
    # @param [String] language_code
    #  The language ISO 639-1 code
    #
    # @return [Content]
    #  A new instance of ContentManagerSystem::Template with the translated attributes
    #
    def translate(language_code)
      
      template = nil
    
      if template_translation = ::ContentManagerSystem::Translation::TemplateTranslation.get(id)
        
        translated_attributes = {}
        
        template_translation.get_translated_attributes(language_code).each do |term| 
          translated_attributes.store(term.concept.to_sym, term.translated_text)
        end

        template = Template.new(attributes.merge(translated_attributes){ |key, old_value, new_value| new_value.to_s.strip.length > 0?new_value:old_value }) 
      else
        template = self       
      end
      
      template.language_code = language_code
    
      template
    
    end    

  end

end