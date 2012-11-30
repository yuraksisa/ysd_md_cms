require 'data_mapper' unless defined?DataMapper
require 'ysd_md_translation' unless defined?Model::Translation::Translation

module ContentManagerSystem
  module Translation

      #
      # Term translation
      #
      class TermTranslation
        include ::DataMapper::Resource

        storage_names[:default] = 'trans_term_translation'
 
        belongs_to :term, 'ContentManagerSystem::Term', :child_key => [:term_id], :parent_key => [:id], :key => true
        belongs_to :translation, 'Model::Translation::Translation', :child_key => [:translation_id], :parent_key => [:id]
        
        #
        # Creates or updates a term translation
        #
        def self.create_or_update(term_id, language_code, attributes)
       
          term_translation = nil
          
          TermTranslation.transaction do 

            term_translation = TermTranslation.get(term_id)
            
            if term_translation
              term_translation.set_translated_attributes(language_code, attributes)            
            else
              translation = Model::Translation::Translation.create_with_terms(language_code, attributes) 
              term_translation = TermTranslation.create({:term => ::ContentManagerSystem::Term.get(term_id), 
                                                         :translation => translation})
            end
             
          end       
        
          term_translation
        
        end
        
        #
        # Get the term translated attributes
        #
        # @param [String] language_code
        #  The language code
        #
        # @return [Array]
        #  An array of TranslationTerm which contains all the translations terms in the request language
        #
        def get_translated_attributes(language_code)
        
          Model::Translation::TranslationTerm.find_translations_by_language(translation.id, language_code)
        
        end
        
        #
        # Updates the translated attributes
        #
        # @param [Numeric] term_id
        #  The term id
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
        
        
      end #TermTranslation

  end #Translation
end #ContentManagerSystem    
