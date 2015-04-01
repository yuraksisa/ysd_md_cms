require 'ysd-plugins' unless defined?Plugins::ModelAspect

module ContentManagerSystem
  module FieldSet
    #
    # It defines an aspect to allow comments to a model
    #
    module Commentable
      include ::Plugins::ModelAspect

       def self.included(model)

         if model.respond_to?(:property)
           #model.property :comments_opened, Boolean # The users can create comments
         end

       end
    end
  end
end