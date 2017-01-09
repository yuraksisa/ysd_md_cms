require 'ysd_md_publishing_state'
require 'ysd_md_publishing_action'
require 'ysd_md_publishing_workflow_step'
require 'ysd-md-user-connected_user'

module ContentManagerSystem
  #
  # The publishing work flow
  #
  class PublishingWorkFlow
    include Users::ConnectedUser

    attr_reader :id, :description, :initial_state, :steps
    
    #
    # Creates a publishing workflow
    #
    # @params [String] id
    #  The workflow id
    #
    # @params [String] description
    #  The workdlow description
    #
    # @params [PublishingState] initial_state
    #
    # @params [Array] flow
    #  Array of WorkflowStep
    #
    #
    def initialize(id, description, initial_state, steps)
      @id = id
      @description = description
      @initial_state = initial_state
      @steps = steps
      self.class.workflows << self 
    end

    #
    # Retrieve the steps that can be applied to a publication
    #
    # The depend on the publication's current state, the publication composer and the current connected user
    #
    # @param [ContentManagerSystem::Publishable] the publication
    #
    # @param [ContentManagerSystem::PublishingAction] the action to perform
    #  It's optional. If it's specified only get the available steps for the action else get the 
    #  the available steps for all the options
    #
    # return [Array] of WorkFlowStep
    #  The available steps
    #
    def available_steps(publication, action=nil)

      available_steps = steps.select do |step|
         (step.current_state == publication.publishing_state) and
         (not (step.composer_usergroups & publication.composer_user.usergroups.map{|usergroup| usergroup.group}).empty?) and # composer usergroups
         (not (step.executor_usergroups & connected_user.usergroups.map{|usergroup| usergroup.group}).empty?)                    # executor usergroups
      end
     
      unless action.nil?
       available_steps.select! { |step| step.action == action }
      end

      return available_steps

    end
    
    #
    # Check if an action is accepted for a publication
    #
    # @return [Boolean]
    #
    def is_accepted?(publication, action)

      available_steps(publication, action).length > 0

    end

    #
    # Get the next publishing of publication from it current step and an action
    #
    # @param [ContentManagerSystem::Publishable] the publication
    # @param [ContentManagerSystem::PublishingAction] the action
    #
    # @return [ContentManagerSystem::PublishingState] or nil if there is no step
    #
    def next_state(publication, action)

      next_state = if is_accepted?(publication, action) and step = available_steps(publication, action).first
                     step.new_state
                   else
                     nil
                   end

    end

    #
    # Get all the defined workflows
    #
    # @return [Array] of ContentManagerSystem::PublishingWorkFlow
    #
    def self.workflows
      @workflows ||= []
    end
    
    #
    # Get all the defined workflows
    #
    def self.all
      return self.workflows
    end

    #
    # Get a workflow by its id
    #
    def self.get(id)
      
      (all.select {|wf| wf.id == id}).first

    end

    #
    # Retrieve the json version of the object
    #
    def to_json(*a)
    
      { :id => id,
        :description => description,
      }.to_json
     
    end

    STANDARD_WORKFLOW = new('standard', "Standard publishing (for registered users)", PublishingState::INITIAL,
                             [WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::SAVE, PublishingState::DRAFT, ['user','staff','webmaster','editor'], ['user','staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user','staff','webmaster','editor'], ['user','staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::SAVE, PublishingState::DRAFT, ['user', 'staff','webmaster','editor'], ['user', 'staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user', 'staff','webmaster','editor'], ['user','staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::BAN, PublishingState::BANNED, ['user', 'staff','webmaster','editor'], ['staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::BANNED, PublishingAction::ALLOW, PublishingState::PUBLISHED, ['user', 'staff','webmaster','editor'], ['staff','webmaster','editor'])
                              ])

    STANDARD_ANONYMOUS_WORKFLOW = new('standard_anonymous', 'Standard publishing (including anoymous users)', PublishingState::INITIAL,
                             [WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PENDING_CONFIRMATION, ['anonymous'],['anonymous']),
                              WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::SAVE, PublishingState::DRAFT, ['user','staff','webmaster','editor'], ['user', 'staff','webmaster','editor']),
    	                        WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user', 'staff','webmaster','editor'], ['user', 'staff','webmaster','editor']),
                              WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::SAVE, PublishingState::DRAFT, ['user', 'staff','webmaster','editor'], ['user', 'staff','webmaster','editor']),
                              WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user', 'staff','webmaster','editor'], ['user', 'staff','webmaster','editor']),
                              WorkFlowStep.new(PublishingState::PENDING_CONFIRMATION, PublishingAction::CONFIRM, PublishingState::PUBLISHED, ['anonymous'], ['anonymous']),
    	                        WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::BAN, PublishingState::BANNED, ['anonymous', 'user', 'staff','webmaster','editor'], ['staff','webmaster','editor']),
                              WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::SAVE, PublishingState::PUBLISHED, ['anonymous', 'user', 'staff','webmaster','editor'], ['anonymous', 'user', 'staff','webmaster','editor']),
    	                        WorkFlowStep.new(PublishingState::BANNED, PublishingAction::ALLOW, PublishingState::PUBLISHED, ['anonymous', 'user', 'staff','webmaster','editor'], ['staff','webmaster','editor'])
    	                       ])

    VALIDATION_WORKFLOW = new('validation', 'Validation: Staff validates content before its published', PublishingState::INITIAL,
    	                        [WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::SAVE, PublishingState::DRAFT, ['user','staff','webmaster','editor'], ['user','staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PENDING_CONFIRMATION, ['anonymous'], ['anonymous']),  	                         
                               WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PENDING_VALIDATION, ['user','webmaster','editor'], ['user','webmaster','editor']),
    	                         WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['anonymous','user','staff','webmaster','editor'], ['staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::PUBLISH, PublishingState::PENDING_VALIDATION, ['user','webmaster','editor'], ['user','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user','staff','webmaster','editor'], ['staff','webmaster','editor']),
    	                         WorkFlowStep.new(PublishingState::PENDING_CONFIRMATION, PublishingAction::CONFIRM, PublishingState::PENDING_VALIDATION, ['anonymous'], ['anonymous']),
    	                         WorkFlowStep.new(PublishingState::PENDING_VALIDATION, PublishingAction::VALIDATE, PublishingState::PUBLISHED, ['anonymous','user','webmaster','editor'], ['staff','webmaster','editor']),
    	                         WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::BAN, PublishingState::BANNED, ['anonymous','user','staff','webmaster','editor'], ['staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::SAVE, PublishingState::PENDING_VALIDATION, ['anonymous', 'user','webmaster','editor'], ['staff','webmaster','editor']),
                               WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::SAVE, PublishingState::PUBLISHED, ['staff','webmaster','editor'], ['staff','webmaster','editor']),
    	                         WorkFlowStep.new(PublishingState::BANNED, PublishingAction::ALLOW, PublishingState::PUBLISHED, ['anonymous','user','staff','webmaster','editor'], ['staff','webmaster','editor'])
    	                        ])    	

    COMMENTS_WORKFLOW = new('comments', 'Comments workflow (for registered users)', PublishingState::INITIAL,
                            [WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user','staff','webmaster','editor'], ['user','staff','webmaster','editor']),
                             WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::BAN, PublishingState::BANNED, ['user', 'staff','webmaster','editor'], ['staff','webmaster','editor']),
                             WorkFlowStep.new(PublishingState::BANNED, PublishingAction::ALLOW, PublishingState::PUBLISHED, ['user', 'staff','webmaster','editor'], ['staff','webmaster','editor'])                             
                            ]
                            )

    COMMENTS_ANONYMOUS_WORKFLOW = new('comments_anonymous', 'Comments workflow (including anonymous users)', PublishingState::INITIAL,
                            [WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user','staff','webmaster','editor'], ['user','staff','webmaster','editor']),
                             WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PENDING_VALIDATION, ['anonymous'], ['anonymous']),
                             WorkFlowStep.new(PublishingState::PENDING_VALIDATION, PublishingAction::VALIDATE, PublishingState::PUBLISHED, ['anonymous','staff','webmaster','editor'], ['staff','webmaster','editor']),
                             WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::BAN, PublishingState::BANNED, ['anonymous', 'user', 'staff','webmaster','editor'], ['staff','webmaster','editor']),
                             WorkFlowStep.new(PublishingState::BANNED, PublishingAction::ALLOW, PublishingState::PUBLISHED, ['anomymous', 'user', 'staff','webmaster','editor'], ['staff','webmaster','editor'])                             
                            ]
                            )

  end
end