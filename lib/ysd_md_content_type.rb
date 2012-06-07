require 'data_mapper' if not defined?(DataMapper)

#
module ContentManagerSystem

  #
  # It represents a content type 
  #
  class ContentType
    include DataMapper::Resource

    storage_names[:default] = 'cms_content_types'

    property :id, String, :field => 'id', :length => 20, :key => true    
    property :name, String, :field => 'name', :length => 50
    property :description, String, :field => 'description', :length => 256

  end #ContentType
end