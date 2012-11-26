module ContentManagerSystem
  class PublishingState

    attr_reader :id, :description

    private_class_method :new

    #
    # Gets an state by its id
    #
    def self.get(id)
      (PublishingState::STATES.select { |item| item.id == id }).first
    end

    #
    # Retrieve all the states
    #
    def self.all
      return STATES
    end

    #
    # Constructor
    #
    def initialize(id, description)
      @id = id
      @description = description
    end

    #
    # Retrieve the json version of the object
    #
    def to_json(*a)
    
      { :id => id,
        :description => description,
      }.to_json
     
    end

    #
    # Define the valid states
    #
    INITIAL = new(nil, 'Initial')
    DRAFT = new('DRAFT', 'Draft')
    PENDING_CONFIRMATION = new('PEND_CONF', 'Pending of confirmation')
    PENDING_VALIDATION = new('PEND_VALID', 'Pending of validation')
    PUBLISHED = new('PUBLISHED', 'Published')
    BANNED = new('BANNED', 'Banned')

    STATES = [INITIAL, DRAFT, PENDING_CONFIRMATION, PENDING_VALIDATION, PUBLISHED, BANNED]

  end
end