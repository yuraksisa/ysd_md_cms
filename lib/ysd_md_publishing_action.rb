module ContentManagerSystem
  class PublishingAction

    attr_reader :id, :description
    
    private_class_method :new

    def initialize(id, description)
      @id = id
      @description = description
    end
    
    #
    # Retrieve an action by its id
    #
    def self.get(id) 
      (ACTIONS.select { |action| action.id==id}).first
    end
    
    #
    # Retrieve all the actions
    #
    def self.all
      ACTIONS
    end

    #
    # Retrieve the json version of the object
    #
    def to_json(*a)
    
      { :id => id,
        :description => description,
      }.to_json
     
    end

    SAVE     = new('SAVE', 'Stores the publication but not publish it')
    PUBLISH  = new('PUBLISH', 'Publish')
    CONFIRM  = new('CONFIRM', 'Confirm the publication. The composer confirms the publication through the email')
    VALIDATE = new('VALIDATE', 'Validate the publication. The element will be online')
    BAN      = new('BAN', 'Ban(proscribe) the publication')
    ALLOW    = new('ALLOW', 'Reactivate a banned publication')

    ACTIONS  = [SAVE, PUBLISH, CONFIRM, VALIDATE, BAN, ALLOW]    

  end
end