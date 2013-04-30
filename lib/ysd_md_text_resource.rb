require 'data_mapper' unless defined?DataMapper
require 'ysd_md_rac' unless defined?Users::ResourceAccessControl
require 'ysd_md_audit' unless defined?Audit::Auditor

module ContentManagerSystem
  #
  # It represents a text resource that can be retrieved from an URL.
  # The resource stores it content in a template. For example : CSS, Javascript
  #
  # Resources can expose an URL that can be used to retrieve the content of the
  # mime_type specified
  #
  # Usage:
  #
  # my_css = ContentManagerSystem::Template.create(:name => 'style.css', 
  #          :text => 'h2 { .... } ')
  # 
  # my_resource = ContentManagerSystem::Resource.create(:template => my_css,
  #          :mime_type => 'text/css', :alias => 'style.css')
  #  
  # Then in the browser, we can retrieve the resource using:
  #
  # http://miurl/style.css
  #
  #
  class TextResource
     include DataMapper::Resource
     include Users::ResourceAccessControl
     include Audit::Auditor
    
     storage_names[:default] = 'cms_text_resources'

     property :id, Serial
     belongs_to :template
     property :alias, String, :length => 80, :unique_index => :cms_text_resources_alias
     property :mime_type, String, :length => 60

     def self.find_by_alias(search_alias)
        first(:alias => search_alias)
     end

  end
end