require 'yaml' if not defined?(YAML)

module ContentManagerSystem
  module Support
    module ContentExtract

      # Parse a file and gets the metadata hold
      # 
      # @param [String] file_path
      #   The file to process
      #
      # @return [Hash]
      #   A hash with the metadata
      #  
      def parse_txt_file(file_path)
  
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
 
         result  
  
      end 
      
     # def parse_txt_file(file_path)
     #
     #    metadata = {}
     #    remaining = ''
     #
     #    File.open(file_path) do |file|
     #   
     #      while (not file.eof?)
     #         line = file.readline            
     #         if match = line.match(/\w*:\s[\w|\s]*/)
     #            key, value = line.split(/:\s/)
     #            #puts "key : #{key} value: #{value}"
     #            metadata.store( key.to_sym, value.gsub(/\n|\n\r/,'') )
     #         else
     #            remaining << line if not line.match(/^\n|\n\r$/)
     #            break
     #         end
     #      end 
     #    
     #      remaining << file.read # Reads the rest of the document
     # 
     #      metadata.store(:body, remaining) if remaining
     # 
     #    end 
     # 
     #    metadata  
     #
     # end 
      
    end # ContentExtract
    
  end # end Support
end # end Persistence