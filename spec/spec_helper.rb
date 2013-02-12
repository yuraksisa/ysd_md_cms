#
# Before running
#
# Make sure sqlite is installed
#
#   - brew install sqlite
#
# Make sure rspec gem is installed
#
#
require 'data_mapper'
require 'ysd_md_searchable'
Model::Searchable.configure({:language => :en, :default_strategy => 'bonsai'})
require 'ysd_md_cms'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup :default, "sqlite3::memory:"
DataMapper::Model.raise_on_save_failure = true
DataMapper.finalize 

DataMapper.auto_migrate!