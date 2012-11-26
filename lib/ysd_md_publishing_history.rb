require 'data_mapper' unless defined?DataMapper

module ContentManagerSystem
  #
  # It represents a content publishing history record
  #	
  class PublishingHistory
  	include DataMapper::Resource

    storage_names[:default] = 'cms_publishing_history'

    property :id, Serial, :field => 'id', :key => true
    property :state, String, :field => 'state', :length => 10
    property :user, String, :field => 'user', :length => 20
    property :date, DateTime, :field => 'date'

  end
end