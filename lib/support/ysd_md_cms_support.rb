require 'yaml' if not defined?(YAML)

module ContentManagerSystem
  module Support
    module ContentExtractor

      # Parse a file and gets the metadata hold
      # 
      # @param [String] file_path
      #   The file to process
      #
      # @return [Hash]
      #   A hash with the metadata
      #  
      def parse_content_file(file_path)
  
         result = {}
         metadata = []
         remaining = ''
  
         File.open(file_path) do |file|
        
           while (not file.eof?)
              line = file.readline            
              if match = line.match(/\w*:\s[\w|\s]*/)
                 metadata.push(line)
              else
                 remaining << line if not line.match(/^\n|\n\r$/)
                 break
              end
           end 
         
           remaining << file.read # Reads the rest of the document

           result = {}
           
           if metadata and metadata.length > 0 
            result = YAML::load(metadata.join)
           end
           
           result.store(:body, remaining) if remaining
    
         end 
 
         return result  
  
      end 

    end # ContentExtract
    
  end # end Support
end # end Persistence