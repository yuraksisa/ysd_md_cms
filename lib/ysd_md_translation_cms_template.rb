require 'data_mapper' unless defined?DataMapper
require 'ysd_md_translation' unless defined?Model::Translation::Translation

module ContentManagerSystem
  module Translation
      #
      # Template Translation
      #  
      # It represents the translation of a template
      #
      class TemplateTranslation
        include ::DataMapper::Resource
      
        storage_names[:default] = 'trans_template_translation'
        
        belongs_to :template, 'ContentManagerSystem::Template', :parent_key => [:id], :child_key => [:template_id], :key => true
        belongs_to :translation, 'Model::Translation::Translation', :child_key => [:translation_id], :parent_key => [:id]
        
        def destroy
          transaction do
            super
            translation.destroy
          end
        end

        #
        # Creates or updates the template translation
        #
        def self.create_or_update(template_id, language_code, attributes)
        
          template_translation = nil
          
          TemplateTranslation.transaction do 
         
            template_translation = TemplateTranslation.get(template_id)                  
          
            if template_translation
              template_translation.set_translated_attributes(language_code, attributes)
            else
              begin
                translation = Model::Translation::Translation.create_with_terms(language_code, attributes) 
                template = ContentManagerSystem::Template.get(template_id)
                template_translation = TemplateTranslation.new({:template => template, :translation => translation})
                template_translation.save
              rescue  DataMapper::SaveFailureError => error
                p "ERRORS: #{error} template valid: #{template.valid?} translation valid: #{template_translation.valid?}"
                raise error 
              end
            end
            
          end
          
          template_translation
        
        end
        
        #
        # Find the template translated attributes 
        #
        # @param [String] language_code
        #  The language
        #
        # @return [Array]
        #  An array of TranslationTerm which contains the translated terms associated to the template
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
