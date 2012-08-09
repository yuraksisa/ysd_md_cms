require 'data_mapper' unless defined?DataMapper

module ContentManagerSystem

  #
  # It represents a tied comment set which can be used in any application to hold comments
  #
  class CommentSet
    include DataMapper::Resource
    
    storage_names[:default] = 'cms_comment_sets'
   
    property :id, Serial, :field => 'id', :key => true
    property :reference, String, :field => 'reference', :length => 64 # It's an external reference which can be used to create the comment set
    property :status, String, :field => 'status', :length => 1        # The comments status : Open or Closed
    
    #
    # get the comment set by the reference
    # TODO create an index
    #
    def self.get_by_reference(reference)
    
      CommentSet.first({:reference => reference})
    
    end
    
  end
  
  #
  # It represents a simple comment
  #
  class Comment
    include DataMapper::Resource
    
    storage_names[:default] = 'cms_comments'
        
    property :id, Serial, :field => 'id', :key => true
    property :date, DateTime, :field => 'date'          # the date the message is published
    property :message, Text, :field => 'text'           # the message
    belongs_to :comment_set, 'ContentManagerSystem::CommentSet', :child_key => [:comment_set_id], :parent_key => [:id]
    belongs_to :parent_comment, 'ContentManagerSystem::Comment', :child_key => [:parent_id], :parent_key => [:id], :required => false
    
    property :guest_publisher_email, String, :field => 'guest_publisher_email', :length => 64      # Anonymous comment email
    property :guest_publisher_name, String, :field => 'guest_publisher_name', :length => 64        # Anonymous comment name
    property :guest_publisher_website, String, :field => 'guest_publisher_website', :length => 40  # Anonymous comment website
    
    property :publisher_account, String, :field => 'publisher_account', :length => 32              # Internal account

    property :external_publisher_provider, String, :field => 'external_publisher_provider', :length => 32 # External provider
    property :external_publisher_account, String,  :field => 'external_publisher_account', :length => 64  # External account        
    
    alias old_save save
    
    #
    # Before saving a comment, initializes the comment date
    #
    before :save do |comment|
    
      if not comment.date
        comment.date = Time.now
      end
    
    end
    
    #
    # Saves a comment
    #
    def save
    
      transaction do |transaction|
        if comment_set and not comment_set.saved?
          if comment_set.id 
            puts "comment set exists #{comment_set.id}"
            comment_set_id = comment_set.id
            self.comment_set = CommentSet.get(comment_set_id)         
          end
        end
        old_save
        transaction.commit
      end
      
    end
    
    #
    # Finds the comments which belongs to a comment set
    #
    def self.find_comments(comment_set_id, limit=10, offset=0)
    
      data = Comment.all(:comment_set => {:id => comment_set_id}, :order => [:id.desc], :limit => limit, :offset => offset)
      total = Comment.count(:comment_set_id => comment_set_id)
      
      [data, total]
      
    end
    
  end
  
end