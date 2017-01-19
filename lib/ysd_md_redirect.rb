module ContentManagerSystem
  #
  # It helps to build a web page from other models
  #	
  class Redirect
    include DataMapper::Resource	    
    extend  Yito::Model::Finder
    
    storage_names[:default] = 'cms_redirect'

    property :id, Serial

    property :source, String, :length => 255 
    property :destination, String, :length => 255
    property :redirection_type, Integer

  end
end