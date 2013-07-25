require 'dm-types'
require 'data_mapper' unless defined?DataMapper
require 'ysd-persistence' if not defined?(Persistence)
require 'ysd_md_comparison' unless defined?Conditions::AbstractComparison

module ContentManagerSystem

  # Defines an exception to check when the password is not valid
  #
  class ViewArgumentNotSupplied < RuntimeError; end

  #
  # It represents a view of data
  # 
  #
  class View
    include DataMapper::Resource
    
    storage_names[:default] = 'cms_views'
    
    property :view_name, String, :field => 'view_name', :length => 32, :key => true
    property :description, String, :field => 'description', :length => 256
    
    # The view query
    property :model_name, String, :field => 'model_name', :length => 256 # The model which will be used to retrieve the data            
    property :query_conditions, Json, :field => 'query_conditions', :required => false, :default => {}
    property :query_order, Json, :field => 'query_order', :required => false, :default => []
    property :query_arguments, Json, :field => 'query_arguments', :required => false, :default => []
    
    # The view style
    property :style, String, :field => 'style', :length => 10                      # The style of the view (teaser, fields, ...)
    property :v_fields, Json, :field => 'v_fields', :required => false, :default => [] # The fields   
    property :render, String, :field => 'render', :length => 10                    # The render which will be used
    property :render_options, Json, :field => 'render_options', :required => false, :default => {} # The render options
    
    # The view result/pagination
    property :view_limit, Integer, :field => 'view_limit', :default => 0     # To limit the number of elements to retrieve
    property :pagination, Boolean, :field => 'pagination', :default => false # It allow to paginate the results
    property :ajax_pagination, Boolean, :field => 'ajax_pagination', :default => false # The pagination is done by ajax request
    property :page_size, Integer, :field => 'page_size', :default => 0       # The page size
    property :pager, String, :field => 'pager', :length => 20, :default => 'default'
    property :show_number_of_results, Boolean, :field => 'show_number_of_results', :default => false
    property :num_of_results_text, String, :field => 'num_of_results_text', :length => 80
    property :num_of_results_no_data_text, String, :field => 'num_of_results_no_data_text', :length => 80
    property :num_of_results_1_data_text, String, :field => 'num_of_results_1_data_text', :length => 80

    # The view page
    property :title, String, :field => 'title', :length => 80 # The view title
    property :page_author, String, :field => 'page_author', :length => 80
    property :page_language, String, :field => 'page_language', :length => 3 
    property :page_description, Text, :field => 'page_description' 
    property :page_summary, Text, :field => 'page_summary' 
    property :page_keywords, Text, :field => 'page_keywords'
    property :cache_life, Integer, :field => 'cache_life', :default => 0
    property :header, Text, :field => 'header' # Header text
    property :footer, Text, :field => 'footer' # Footer text
    property :script, Text, :field => 'script' # Script 
    property :page_style, Text, :field => 'page_style'   # Style
    property :url, String, :field => 'url', :length => 256    # The url from which it can be accessed
    
    # Other view options
    property :block, Boolean, :field => 'block', :default => false
    
    # Retrieves data from the data_repository
    #
    # @param [String] arguments
    #   A string which represents the query arguments, separated by an slash
    #   Example:
    #     /param1/param2
    #     There are two parameters, param1 and param2   
    #
    # @return [Array]
    #   The data that matches the query
    #
    def get_data(page=1, arguments="", context={})

      the_model = (DataMapper::Model.descendants.select { |model| model_name == model.name.scan(/\w+$/)[0].downcase }).first
      
      unless the_model
        puts "The model is not defined. Has you require it?"
      end

      vc = view_conditions(arguments, context)
      
      q_total_records = 0      # The view total records
      q_total_pages = 0        # The view total pages
      q_data = []              # The view data (query result)
      q_page = page            # The view page that is being retrieved
      q_page_size = page_size  # The view page size

      if the_model
        
        # Counts 
        if vc.comparison.nil?
            q_total_records = the_model.count
        else
            q_total_records = vc.comparison.build_datamapper(the_model).all.count 
        end

        q_page_size = q_total_records if q_page_size == 0

        if q_total_records > 0

          query_order = {} 
          if vo=view_order and not vo.empty?
            query_order.store(:order, vo.map { |vo_item| DataMapper::Query::Operator.new(vo_item.field.to_sym, vo_item.order.to_sym) })
          end

          query_limit = {}
          if (q_page < 1) or (q_page > (q_total_records/q_page_size))
            q_page = 1
          end
          if pagination
            query_limit.store(:limit,  q_page_size)
            query_limit.store(:offset, q_page_size * (q_page - 1))
          else
            if view_limit > 0
              query_limit.store(:limit, view_limit)
            end
          end

          if pagination and q_page_size >= 1
            q_total_pages = (q_total_records/q_page_size).ceil       
          end
                                                             
          if vc.comparison.nil?
            q_data = the_model.all(query_order.merge(query_limit))
          else
            q_data = vc.comparison.build_datamapper(the_model, query_order.merge(query_limit))
          end
        
        end

      end

      return {:summary => {:total_records => q_total_records, :total_pages => q_total_pages, :current_page => q_page }, :data => q_data}     
     
    end

    @processed_conditions = false
    @the_view_fields = nil
    @the_view_conditions = nil
    @the_view_order = nil
    @the_view_arguments = nil
    
    #
    # Get the view fields
    #
    # @return [Array] 
    #
    #   Array of ViewField
    #
    def view_fields
      
      if @the_view_fields.nil?
        @the_view_fields = []
        unless v_fields.nil? 
          v_fields.each do |one_field|
            @the_view_fields << ViewField.new(one_field)
          end
        end
      end
      
      return @the_view_fields
          
    end
    
    #
    # Get the view conditions
    # 
    # @return
    #
    def view_conditions(arguments_values='', context={})
    
      unless @processed_conditions 
        if not query_conditions.nil? and not query_conditions.empty?
          @the_view_conditions = ViewQueryConditions.new(query_conditions, view_arguments, arguments_values, context)
        end
      end
      
      return @the_view_conditions
    
    end
    
    #
    # Get the view order
    #
    def view_order
 
      if @the_view_order.nil?
        @the_view_order = []
        if not query_order.nil?
          query_order.each do |query_order_field|
            @the_view_order << ViewQueryOrder.new(query_order_field)
          end
        end
      end

      return @the_view_order
    
    end    
    
    #
    # Get the view arguments
    #
    def view_arguments
    
      if @the_view_arguments.nil?
        @the_view_arguments = {}
        if not query_arguments.nil?
          query_arguments.each do |query_argument|
            view_argument = ViewQueryArgument.new(query_argument)
            @the_view_arguments.store(view_argument.order, view_argument) 
          end
        end
      end
            
      return @the_view_arguments    
    
    end    
    
        
  end #View        
        
  #
  # Represents a view field
  #
  class ViewField
      
      attr_reader :field, :class, :link, :image, :link_class, :image_class, :image_alt
      
      def initialize(opts={})
        
        @field = opts['field']
        @class = opts['class']
        
        @link  = opts['link']
        @link_class = opts['link_class']
               
        if opts.has_key?('image')
          @image = opts['image'] 
        else
          @image = false
        end
        @image_class = opts['image_class']
        @image_alt = opts['image_alt']
      end
      
      def evaluate_link(element)
      
        if @link.match('element')
         eval('"'<<@link<<'"') 
        else
         @link
        end
        
      end

      def evaluate_image_alt(element)
        if @image_alt.match('element')
          eval('"'<<@image_alt<<'"')
        else
          @image_alt
        end
      end
      
  end
    
  #
  # Represents the query conditions 
  #
  class ViewQueryConditions
    
      attr_reader :comparison, :view_arguments, :arguments_values, :context
    
      def initialize(opts={}, v_arguments, arguments, the_context)
        @context = the_context || {}
        @view_arguments = v_arguments                    # the arguments definitions
        @arguments_values = extract_arguments(arguments) # the arguments values      
        @comparison = process_comparison(opts)
      end

      private 
      
      #
      # Build the query conditions
      #
      def process_comparison(opts={})
      
        if opts.has_key?('conditions') # join comparison
          process_join_comparison(opts)
        else
          process_simple_comparison(opts)
        end
      
      end
      
      #
      # Join comparison
      #
      def process_join_comparison(opts={})
      
        operator   = opts['operator']
        conditions = opts['conditions'].map do |condition|
                       process_comparison(condition)
                     end

        conditions.delete_if { |condition| condition.nil? } # remove nil conditions (not arguments supplied)
        
        conditions = if conditions.length > 1
                       Conditions::JoinComparison.new(operator, conditions)
                     else 
                       if conditions.length == 1
                         conditions.first
                       else 
                         nil
                       end
                     end
        
        return conditions

      end
      
      #
      # Simple comparison
      #
      # @throw ViewArgumentNotSupplied
      #
      def process_simple_comparison(opts={})
        
        comparison = nil
        value = opts['value']
        if value.kind_of?(String)
          argument_in_value, value = process_value(value)  
          if argument_in_value 
            if value.nil?
              check_none_supplied_argument(argument_in_value)
            else
              if check_supplied_argument(argument_in_value, value)
                comparison = Conditions::Comparison.new(opts['field'], opts['operator'], value) 
              end
            end
          else
            comparison = Conditions::Comparison.new(opts['field'], opts['operator'], eval_value(value))
          end  
        else
          if value.kind_of?(Array)
            values = []
            value.each do |value_item|
              if value_item.kind_of?(String)
                argument_in_value, value_item = process_value(value_item) 
                if argument_in_value # the condition array item includes an argument
                  if value_item.nil? 
                    check_none_supplied_argument(argument_in_value)
                  else
                    values << value_item if check_supplied_argument(argument_in_value, value_item)
                  end
                else
                  values << eval_value(value_item)
                end
              else
                values << value_item
              end
            end
            comparison = Conditions::Comparison.new(opts['field'], opts['operator'], values) if values.length > 0
          else
            comparison = Conditions::Comparison.new(opts['field'], opts['operator'], value)
          end
        end
        
        return comparison

      end
    
      private
      
      #
      # Eval the value
      #
      def eval_value(value)

        me = nil 
        content = nil
        profile = nil 

        unless context.nil?
          me      = context[:me]
          content = context[:current_content]
          profile = context[:current_profile]
        end

        if value.match(/#\{(.+)\}/)
         eval('"'<<value<<'"') 
        else
         value
        end
        
      end

      #
      # Check howto act when the argument is not supplied
      #
      # @throws ViewArgumentNotSupplied if the argument is required and not supplied
      #
      def check_none_supplied_argument(argument_order)
        if argument = view_arguments[argument_order] and argument.error_not_supplied_strategy?
           raise ViewArgumentNotSupplied, "The argument #{argument_order} #{argument.name} is not supplied"
        end 
      end
      
      #
      # Check howto act when the argument is supplied
      #
      # @return true if apply the condition or false if the value match the wildcard
      #
      def check_supplied_argument(argument_order, value)

        apply_condition = false
        
        if argument = view_arguments[argument_order] and value != argument.wildcard
          apply_condition = true
        end

        return apply_condition
      end

      #
      # Analize the condition value and replace it from arguments if it necesary
      # @param [Object]
      #   The condition value
      #
      # @return [Array]
      #   The condition value after replace it with arguments or the value if it's a primitive value
      #   return nil if the value implies a argument replacement and it doesn't be 
      #
      def process_value(value)
        
        result = if argument = argument_in_value(value)
                   if view_arguments.has_key?(argument) and arguments_values.has_key?(argument.to_sym)
                     view_arguments[argument].typecast(value % arguments_values)
                   end
                 else
                   value
                 end

        return [argument, result]

      end

      #
      # Get the argument key that exist in the value
      #
      # @return [String]
      #
      #  The argument represented in the value
      #
      def argument_in_value(value)
        
        if condition_argument=value.match(/\{(\d+)\}/)
          condition_argument[1] 
        end

      end

      #
      # Extract the query argument values from the string
      #
      # @return [Hash] the query arguments
      #   The key is the element order and the value is the element value
      #
      def extract_arguments(arguments='')
        
        arguments ||= ''
        a_arguments = arguments.split("/")
        a_arguments.delete('')    
      
        h_arguments={}
      
        a_arguments.each_index do |index|
          h_arguments.store(index.to_s.to_sym, @view_arguments[index.to_s].typecast(a_arguments[index])) if @view_arguments.has_key?(index.to_s)
        end
        
        return h_arguments
    
     end    
    
  end
    
  #
  # Represent the query order
  #
  class ViewQueryOrder
      
      attr_reader :field, :order
         
      def initialize(opts={})
      
        @field = opts['field']
        @order = opts['order']
      
      end
    
  end

  #
  # Represent a query argument
  #
  class ViewQueryArgument
      
      attr_reader :order, :default, :wildcard, :type, :not_supplied_strategy
         
      def initialize(opts={})
      
        @order    = opts['order']
        @default  = opts['default']
        @wildcard = opts['wildcard'] || 'all'
        @type     = opts['type']
        @name     = opts['name']
        @not_supplied_strategy = opts['not_supplied_strategy'] || 'all'
      
      end
    
      def typecast(value)
      
        return_value = case type
                         when 'integer'
                            value.to_s.to_i
                         else
                            value
                       end
              
      end

      def error_not_supplied_strategy?
        not_supplied_strategy == 'error'
      end
      
      def all_not_supplied_strategy?
        not_supplied_strategy == 'all'
      end

  end
        
end #ContentManagerSystem