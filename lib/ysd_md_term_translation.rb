require 'ysd_md_translation_cms_term'

module ContentManagerSystem
  
  #
  # Reopen the class to extend with the term translation
  #
  module TermTranslation
    
    attr_accessor :language_code
    
    #
    # Translate the term into the language code
    #
    # @param [String] language_code
    #  The language ISO 639-1 code
    #
    # @return [Term]
    #  A new instance of the ContentManagerSystem::Term with the translated attributes
    #
    def translate(language_code)
    
      term = nil
      
      if term_translation = ::ContentManagerSystem::Translation::TermTranslation.get(id)
        translated_attributes = {}
        term_translation.get_translated_attributes(language_code).each {|term| translated_attributes.store(term.concept.to_sym, term.translated_text)}
        term = Term.new(attributes.merge(translated_attributes){ |key, old_value, new_value| new_value.to_s.strip.length > 0?new_value:old_value})
      else
        term = self
      end
    
      term.language_code = language_code
    
      term
      
    end
  
  end


end #ContentManagerSystem