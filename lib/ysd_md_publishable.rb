require 'ysd_md_publishing_state'
require 'ysd-md-user-profile' unless defined?Users::Profile
require 'ysd-md-business_events' unless defined?BusinessEvents::BusinessEvent
require 'ysd-md-user-connected_user'

module ContentManagerSystem
  #
  # Module which can be included in any resource to manage the publish state
  #
  # The classes that include this modules must implement the publication_info method, in order to
  # communicate to business events that a publication has been published
  #
  # This method returns a hash with 2 elements:
  #
  #  :type
  #  :id
  #
  module Publishable
    include Users::ConnectedUser

    #
    # When the model is included in a class
    #
    def self.included(model)
      
      if model.respond_to?(:property)

        model.property :publishing_state_id, String, :length => 10          # The content state (it must be a ContentManagerSystem::PublishedState instance)
        model.property :publishing_workflow_id, String, :length => 20       # The default workflow

        model.property :publishing_date, DateTime                           # The publishing date
        model.property :publishing_publisher, String, :length => 20         # The publisher (user)

        model.property :publishing_confirmation_date, DateTime

        model.property :publishing_validation_date, DateTime
        model.property :publishing_validation_user, String, :length => 20   # The validation user

        model.property :publishing_banned_date, DateTime
        model.property :publishing_banned_user, String, :length => 20       # The banned user

        model.property :publishing_allowed_date, DateTime
        model.property :publishing_allowed_user, String, :length => 20      # The allowed user
        
        model.property :composer_username, String, :length => 20            # The composer user

        model.property :composer_name, String, :length => 80                # The name of the composer (if he/she's an anonymous user)
        model.property :composer_email, String, :length => 50               # The email of the composer (if he/she's an anonymous user)
        model.property :composer_website, String, :length => 50             # The website of the composer (it he/she's an anonymous user)

      end
      
      if model.respond_to?(:before)

        model.before :create do
          init_publishable_data
        end

      end

    end
    
    #
    # Get the available publishing actions depending of the state of the publicable
    #
    # @return [Array] array of ContentManagerSystem::PublishingAction
    #
    def publishing_actions

      actions = []

      if wf = publishing_workflow
        actions= wf.available_steps(self).map { |step| step.action }
      end

      return actions.uniq

    end

    #
    # Save the publication (create a draft)
    #
    def save_publication
      
      init_publishable_data

      if publishing_workflow.is_accepted?(self, PublishingAction::SAVE)
        self.publishing_state_id = PublishingState::DRAFT.id
        save if self.respond_to?(:save)
      end

    end
    
    #
    # Check if the publication is published 
    #
    def is_published?
      self.publishing_state == PublishingState::PUBLISHED
    end

    #
    # Check if the publication is banned
    #
    def is_banned?
      self.publishing_state == PublishingState::BANNED
    end

    #
    # Check if the publication is pending validation
    #
    def is_pending_validation?
      self.publishing_state == PublishingState::PENDING_VALIDATION
    end

    #
    # Check if the publication is pending confirmation
    #
    def is_pending_confirmation?

      self.publishing_state == PublishingState::PENDING_CONFIRMATION

    end

    #
    # Publish the publication
    #
    def publish_publication

      init_publishable_data

      if new_state = publishing_workflow.next_state(self, PublishingAction::PUBLISH)
        self.publishing_state_id = new_state.id 
        if new_state == PublishingState::PUBLISHED
          self.publishing_date = Time.now
          self.publishing_publisher = connected_user.username
        end
        save if self.respond_to?(:save)
        BusinessEvents::BusinessEvent.fire_event(:publication_published, publication_info)
      end

    end    
    
    #
    # Confirm the publication
    #
    def confirm_publication

      if new_state = publishing_workflow.next_state(self, PublishingAction::CONFIRM)
        self.publishing_state_id = new_state.id
        if new_state != PublishingState::PENDING_CONFIRMATION
          self.publishing_confirmation_date = Time.now
        end
        check_published
        save if self.respond_to?(:save)
        BusinessEvents::BusinessEvent.fire_event(:publication_confirmed, publication_info)
      end 

    end

    #
    # Validate the publication
    #
    def validate_publication

      if new_state = publishing_workflow.next_state(self, PublishingAction::VALIDATE)
        self.publishing_state_id = new_state.id
        if new_state != PublishingState::PENDING_VALIDATION
          self.publishing_validation_date = Time.now
          self.publishing_validation_user = connected_user.username
        end
        check_published
        save if self.respond_to?(:save)
        BusinessEvents::BusinessEvent.fire_event(:publication_validated, publication_info)
      end

    end
    
    #
    # Ban (censure) the publication
    #
    def ban_publication

      if new_state=publishing_workflow.next_state(self, PublishingAction::BAN)
        self.publishing_state_id = new_state.id
        if new_state == PublishingState::BANNED
          self.publishing_banned_date = Time.now
          self.publishing_banned_user = connected_user.username
        end
        save if self.respond_to?(:save)
        BusinessEvents::BusinessEvent.fire_event(:publication_banned, publication_info)

      end

    end

    #
    # Allow a banned publication
    #
    def allow_publication

      if new_state=publishing_workflow.next_state(self, PublishingAction::ALLOW)

        self.publishing_state_id = new_state.id
        if new_state != PublishingState::BANNED
          self.publishing_allowed_date = Time.now
          self.publishing_allowed_user = connected_user.username
        end

        save if self.respond_to?(:save)
        BusinessEvents::BusinessEvent.fire_event(:publication_allowed, publication_info)

      end


    end

    #
    # Get the publishing state
    #
    # @return [ContentManagerSystem::PublishedState]
    #
    def publishing_state

      @the_publishing_state ||= PublishingState.get(publishing_state_id)

    end

    #
    # Get the publishing workflow
    #
    def publishing_workflow

      @the_publishing_workflow ||= PublishingWorkFlow.get(publishing_workflow_id)

    end

    #
    # Get the composer user
    #
    def composer_user

      @the_composer_user ||= (Users::Profile.get(composer_username) || Users::Profile.ANONYMOUS_USER)

    end

    private

    def init_publishable_data

          # Sets the composer user
          if self.composer_username.nil? or self.composer_username.empty?
            self.composer_username = connected_user.username 
          end
          
          # Sets the workflow
          if self.publishing_workflow_id.nil? or self.publishing_workflow_id.empty?
            self.publishing_workflow_id = SystemConfiguration::Variable.get_value('cms.default_publishing_workflow', 'standard')
          end

          # Sets the state
          if self.publishing_state_id.nil? or self.publishing_state_id.empty?
            self.publishing_state_id = self.publishing_workflow.initial_state.id || PublishingState::INITIAL.id
          end

    end

    #
    # Check if the publication state is published to assign publishing data
    #
    def check_published

      if self.publishing_state == PublishingState::PUBLISHED
        self.publishing_date = Time.now
      end

    end    

  end
end