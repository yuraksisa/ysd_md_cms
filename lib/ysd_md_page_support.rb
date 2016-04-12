module ContentManagerSystem
  #
  # It helps to build a web page from other models
  #	
  class PageSupport
    include DataMapper::Resource	    
    extend  Yito::Model::Finder
    
    storage_names[:default] = 'cms_page_support'

    property :id, Serial

    property :title, String, :length => 80 # The view title
    property :page_author, String, :length => 80
    property :page_language, String, :length => 3 
    property :page_description, Text  
    property :page_summary, Text 
    property :page_keywords, Text 
    property :cache_life, Integer, :default => 0
    property :header, Text # Header text
    property :footer, Text  # Footer text
    property :script, Text  # Script 
    property :page_style, Text   # Style


  end
end