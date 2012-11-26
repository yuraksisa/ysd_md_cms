module ContentManagerSystem
  #
  # Describes a workflow step : which takes from one state to another
  #
  class WorkFlowStep

    attr_reader :current_state, :action, :new_state, :composer_usergroups, :executor_usergroups

    #
    # Creates a workflow step
    #
    # @param [PublishingState] current_state
    #
    # The current state
    #
    # @param [PublishingAction] action
    #
    #  The action to perform
    #
    # @param [PublishState] new_state
    #
    #  The new state
    #
    # @param [Array] usergroups
    #
    #  Array of the usergroups which can complete the step 
    #
    def initialize(current_state, action, new_state, composer_usergroups, executor_usergroups)
      @current_state = current_state
      @action = action
      @new_state = new_state
      @composer_usergroups = composer_usergroups
      @executor_usergroups = executor_usergroups
    end  	



  end
end