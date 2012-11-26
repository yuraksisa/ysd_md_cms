require 'ysd_md_publishing_state'
require 'ysd_md_publishing_action'
require 'ysd_md_publishing_workflow_step'

module ContentManagerSystem
  #
  # The publishing work flow
  #
  class PublishingWorkFlow

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
    # Retrieve a publication available steps 
    #
    # @param [ContentManagerSystem::Publishable] the publication
    # @param [ContentManagerSystem::PublishingAction] the action
    #
    #  It's optional. If specified only get the available steps for the action
    #
    # return [Array] of WorkFlowStep
    #
    def available_steps(publication, action=nil)

      available_steps = steps.select do |_step|
        _step.current_state == publication.get_publishing_state and
        _step.composer_usergroups.any? { |ug| publication.get_composer_user.usergroups.include?(ug) } and
        _step.executor_usergroups.any? { |ug| publication.connected_user.usergroups.include?(ug) }       
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
                             [WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::SAVE, PublishingState::DRAFT, ['user','staff'], ['user','staff']),
                               WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user','staff'], ['user','staff']),
                               WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::SAVE, PublishingState::DRAFT, ['user', 'staff'], ['user', 'staff']),
                               WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user', 'staff'], ['user','staff']),
                               WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::BAN, PublishingState::BANNED, ['user', 'staff'], ['staff']),
                               WorkFlowStep.new(PublishingState::BANNED, PublishingAction::ALLOW, PublishingState::PUBLISHED, ['user', 'staff'], ['staff'])
                              ])

    STANDARD_ANONYMOUS_WORKFLOW = new('standard_anonymous', 'Standard publishing (including anoymous users)', PublishingState::INITIAL,
                             [WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PENDING_CONFIRMATION, ['anonymous'],['anonymous']),
                              WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::SAVE, PublishingState::DRAFT, ['user','staff'], ['user', 'staff']),
    	                        WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user', 'staff'], ['user', 'staff']),
                              WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::SAVE, PublishingState::DRAFT, ['user', 'staff'], ['user', 'staff']),
                              WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user', 'staff'], ['user', 'staff']),
                              WorkFlowStep.new(PublishingState::PENDING_CONFIRMATION, PublishingAction::CONFIRM, PublishingState::PUBLISHED, ['anonymous'], ['anonymous']),
    	                        WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::BAN, PublishingState::BANNED, ['anonymous', 'user', 'staff'], ['staff']),
                              WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::SAVE, PublishingState::PUBLISHED, ['anonymous', 'user', 'staff'], ['anonymous', 'user', 'staff']),
    	                        WorkFlowStep.new(PublishingState::BANNED, PublishingAction::ALLOW, PublishingState::PUBLISHED, ['anonymous', 'user', 'staff'], ['staff'])
    	                       ])

    VALIDATION_WORKFLOW = new('validation', 'Validation: Staff validates content before its published', PublishingState::INITIAL,
    	                        [WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::SAVE, PublishingState::DRAFT, ['user','staff'], ['user','staff']),
                               WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PENDING_CONFIRMATION, ['anonymous'], ['anonymous']),  	                         
                               WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PENDING_VALIDATION, ['user'], ['user']),
    	                         WorkFlowStep.new(PublishingState::INITIAL, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['anonymous','user','staff'], ['staff']),
                               WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::PUBLISH, PublishingState::PENDING_VALIDATION, ['user'], ['user']),
                               WorkFlowStep.new(PublishingState::DRAFT, PublishingAction::PUBLISH, PublishingState::PUBLISHED, ['user','staff'], ['staff']),
    	                         WorkFlowStep.new(PublishingState::PENDING_CONFIRMATION, PublishingAction::CONFIRM, PublishingState::PENDING_VALIDATION, ['anonymous'], ['anonymous']),
    	                         WorkFlowStep.new(PublishingState::PENDING_VALIDATION, PublishingAction::VALIDATE, PublishingState::PUBLISHED, ['anonymous','user'], ['staff']),
    	                         WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::BAN, PublishingState::BANNED, ['anonymous','user','staff'], ['staff']),
                               WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::SAVE, PublishingState::PENDING_VALIDATION, ['anonymous', 'user'], ['staff']),
                               WorkFlowStep.new(PublishingState::PUBLISHED, PublishingAction::SAVE, PublishingState::PUBLISHED, ['staff'], ['staff']),
    	                         WorkFlowStep.new(PublishingState::BANNED, PublishingAction::ALLOW, PublishingState::PUBLISHED, ['anonymous','user','staff'], ['staff'])
    	                        ])    	

  end
end