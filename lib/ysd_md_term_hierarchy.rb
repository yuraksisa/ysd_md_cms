require 'data_mapper' if not defined?(DataMapper)

#
module ContentManagerSystem

  #
  # It represents a term hierarchy (to build complex taxonomies) 
  #
  class TermHierarchy
    include DataMapper::Resource

    storage_names[:default] = 'cms_terms_hierarchy'

    belongs_to :term, 'Term', :child_key => [:term_id], :parent_key => [:id], :key => true    
    belongs_to :parent_term, 'Term', :child_key => [:parent_term_id], :parent_key => [:id], :key => true
    
  end #TermHierarchy
end #ContentManagerSystem