module ContentManagerSystem
  module FieldSet
    #
    # It allows to link a content with other content which holds the place where something happens
    #
    module ContentPlace
      include ::Plugins::ModelAspect

      def self.included(model)

        if model.respond_to?(:property)
          model.property :content_place, String, :field => 'content_place', :length => 32 # Reference to a content
        end

      end
    
      #
      # Get the content referenced
      #
      # @return [ContentManagerSystem::Content]
      def place
        @place ||= load_content_place
      end

      private
    
      #
      # Load the content place
      #
      def load_content_place
        if content_place and content_place.strip.length > 0
          ContentManagerSystem::Content.get(content_place)
        else
          nil
        end
      end
    end
  end
end