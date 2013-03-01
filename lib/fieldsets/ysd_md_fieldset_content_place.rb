module ContentManagerSystem
  module FieldSet
    #
    # It allows to link a content with other content which holds the place where something happens
    #
    module ContentPlace
      include ::Plugins::ModelAspect

      def self.included(model)

        if model.respond_to?(:belongs_to)
          model.belongs_to :place, 'ContentManagerSystem::Content', :parent_key => [:id], :child_key => [:content_place_id], :required => false
        end
        
      end

      #
      #
      #
      def save
        check_place! if place
      end      

      #
      #
      #
      def as_json(options={})

        relationships = options[:relationships] || {}
        relationships.store(:place,{})

        super(options.merge(relationships))

      end

      private

      def check_place!
        if self.place and (not self.place.saved?) and loaded_place = ContentManagerSystem::Content.get(self.place.id)
          self.place = loaded_place
        end
      end

    end #ContentPlace
  end #FieldSet
end #ContentManagerSystem