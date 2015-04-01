require 'data_mapper' unless defined?DataMapper
require 'ysd_md_yito' unless defined?Yito::Model::Finder
require 'ysd_md_audit' unless defined?Audit::Auditor
require 'ysd_md_template_translation'

module ContentManagerSystem
  #
  # It represents a template (a text resource) that can be used as a resource,
  # model for letters, ....
  #
  class Template
     include DataMapper::Resource
     extend Yito::Model::Finder
     include Audit::Auditor       # Extends the model to Audit
     include TemplateTranslation

     storage_names[:default] = 'cms_templates'

     property :id, Serial
     property :name, String, :length => 80, :unique_index => :cms_templates_name_index
     property :description, String, :length => 256
     property :text, Text
     
     #
     # Find a template by its name
     #
     def self.find_by_name(name)
       first(:name => name)
     end

  end
end