require 'data_mapper' if not defined?(DataMapper)

#
module ContentManagerSystem

  #
  # It represents a term synonym (to help in searches ) 
  #
  class TermSynonym
    include DataMapper::Resource

    storage_names[:default] = 'cms_terms_synonym'

    belongs_to :term, 'Term', :child_key => [:term_id], :parent_key => [:id], :key => true    
    property :synonym, String, :length => 32, :field=>'synonym', :key => true
    
  end #TermHierarchy
end #ContentManagerSystem