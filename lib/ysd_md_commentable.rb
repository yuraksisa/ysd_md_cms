require 'ysd-plugins' unless defined?Plugins::ModelAspect

module ContentManagerSystem
  #
  # It defines an aspect to allow comments to a model
  #
  module Commentable
    include ::Plugins::ModelAspect

     def self.included(model)

       if model.respond_to?(:property)
         model.property :comments_open, Object, :field => 'comments_open' # Check that the users can create comments (CHECK TODO)
       end

     end

  end
end