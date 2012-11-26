module ContentManagerSystem
  #
  # Action that can be done after publishing a publication
  #
  class AfterPublishingAction

    attr_reader :id, :description

    def initialize(id, description)
      @id = id
      @description = description
      self.class.strategies << self
    end
    
    #
    # Get an strategy by its id
    #
    def get(id)
      self.class.strategies.select { |strategy| strategy.id == strategy.id }
    end

    #
    # Get all strategies
    #
    def all
      self.class.strategies
    end

    def self.strategies
      @strategies ||= []
    end    

    REDIRECT_TO_CONTENT = new('REDIRECT_TO_PUBLICATION', 'Redirect to publication page')
    REDIRECT_TO_STATUS = new('REDIRECT_TO_STATUS', 'Redirect to publication status')
    NOTIFY_STATUS = new('NOTIFY_STATUS', 'Notify status')
    NONE = new('NONE', 'It does not do an special action')

  end #AfterPublishingStrategy
end #ContentManagerSystem