require 'data_mapper' if not defined?(DataMapper)

#
module ContentManagerSystem

  #
  # It represents a term relation (to create relationships between ) 
  #
  class TermRelation
    include DataMapper::Resource

    storage_names[:default] = 'cms_terms_relation'

    belongs_to :term, 'Term', :child_key => [:term_id], :parent_key => [:id], :key => true    
    belongs_to :related_term, 'Term', :child_key => [:related_term_id], :parent_key => [:id], :key => true
    
  end #TermHierarchy
end #ContentManagerSystem