require 'singleton'

#
# It creates resources from the file system
#
class ResourceLoader
  include Singleton
  include ContentManagerSystem::Support::ContentExtractor
  
  #
  # Load resources from a directory
  #
  # @param [Model] model
  #   The model to which they belong
  #
  # @param [String] path
  #   Where the files are stored
  #
  def load_files(model, path)
        
    process_directory(path, path, model)
  
  end

  private

  # Process a directory to get all the files 
  #
  # @param [String] file_dir
  #  A directory that will process looking for files
  # 
  # @param [Persistence::Model] model
  #  The model of the resource
  #
  def process_directory(root_path, file_dir, model)
                        
     Dir.foreach(file_dir) do |filename|
                  
        file = File.join(file_dir, filename)
                    
        if File.directory?(file)
          process_directory(root_path, file, model) unless filename.match(/^\./)
        else
          unless filename.match(/^\./)
            metadata = parse_content_file(file)
            model.create(file.gsub(root_path+'/','').gsub(/\.\w+$/,''), metadata)                   
          end
        end
         
     end
      
  end
  


end
