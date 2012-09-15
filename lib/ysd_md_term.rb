require 'data_mapper' if not defined?(DataMapper)

#
module ContentManagerSystem

  #
  # It represents a taxonomy term (or concept) 
  #
  class Term
    include DataMapper::Resource

    storage_names[:default] = 'cms_terms'

    property :id, Serial, :field => 'id', :key => true       
    property :description, String, :field => 'description', :length => 256
    property :weight, Integer, :field => 'weight'
    belongs_to :taxonomy, 'Taxonomy', :child_key => [:taxonomy_id], :parent_key => [:id]
    belongs_to :parent, 'Term', :child_key => [:parent_id], :parent_key => [:id], :required => false
    #has n, :term_hierarchies, 'TermHierarchy', :child_key => [:term_id, :parent_term_id], :parent_key => [:id], :constraint => :destroy
    has n, :term_relations, 'TermRelation', :child_key => [:term_id, :related_term_id], :parent_key => [:id], :constraint => :destroy
    has n, :term_synonyms, 'TermSynonym', :child_key => [:term_id, :synonym], :parent_key => [:id], :constraint => :destroy
    
    alias old_save save
    
    #
    # Overload save method
    #
    #  Make sure that the taxonomy exists
    #
    def save
    
      if (self.taxonomy and not self.taxonomy.saved?)      
        self.taxonomy = Taxonomy.get(self.taxonomy.id)
      end
      
      if (self.parent and not self.parent.saved?)
        self.parent = Term.get(self.parent.id)
      end
     
      old_save
    
    end
    
  end #Term
end #ContentManagerSystem