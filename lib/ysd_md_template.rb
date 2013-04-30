require 'data_mapper' unless defined?DataMapper

module ContentManagerSystem
  #
  # It represents a template (a text resource) that can be used as a resource,
  # model for letters, ....
  #
  class Template
     include DataMapper::Resource
          
     storage_names[:default] = 'cms_templates'

     property :id, Serial
     property :name, String, :length => 80, :unique_index => :cms_templates_name_index
     property :text, Text
     
     #
     # Find a template by its name
     #
     def self.find_by_name(name)
       first(:name => name)
     end

  end
end