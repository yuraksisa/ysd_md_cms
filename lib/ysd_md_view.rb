require 'dm-types'
require 'data_mapper' unless defined?DataMapper
require 'ysd-persistence' if not defined?(Persistence)
require 'ysd_md_comparison' unless defined?Conditions::AbstractComparison

module ContentManagerSystem

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
    
    # The view result/pagination
    property :view_limit, Integer, :field => 'view_limit', :default => 0     # To limit the number of elements to retrieve
    property :pagination, Boolean, :field => 'pagination', :default => false # It allow to paginate the results
    property :ajax_pagination, Boolean, :field => 'ajax_pagination', :default => false # The pagination is done by ajax request
    property :page_size, Integer, :field => 'page_size', :default => 0       # The page size
    property :pager, String, :field => 'pager', :length => 20, :default => 'default'

    # The view page
    property :title, String, :field => 'title', :length => 80 # The view title
    property :header, Text, :field => 'header' # Header text
    property :footer, Text, :field => 'footer' # Footer text
    property :script, Text, :field => 'script' # Script 
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
    def get_data(page=1, arguments="")

      the_model = (Persistence::Model.descendants.select { |model| model_name == model.model_name.downcase }).first  
      
      unless the_model
        the_model = (DataMapper::Model.descendants.select { |model| model_name == model.name.scan(/\w+$/)[0].downcase }).first
      end    
      
      unless the_model
        puts "The model is not defined. Has you require it?"
      end

      query = {}
      
      # conditions
      if vc=view_conditions(arguments)
        if the_model.included_modules.include?(DataMapper::Resource)
          query.store(:conditions, vc.comparison.build_sql)
        else
          query.store(:conditions, vc.comparison)
        end
      end
      
      # pagination
  
      q_total_records = 0      # The view total records
      q_total_pages = 1        # The view total pages
      q_data = []              # The view data (query result)
      q_page = page            # The view page that is being retrieved
      q_page_size = page_size  # The view page size

      if the_model
        q_total_records = the_model.count(query)
      end

      if q_page_size == 0
        q_page_size = q_total_records 
      end

      if q_total_records > 0

        # order
        if vo=view_order
          if the_model.included_modules.include?(DataMapper::Resource)
            query.store(:order, vo.map { |vo_item| DataMapper::Query::Operator.new(vo_item.field.to_sym, vo_item.order.to_sym) })
          else
            query.store(:order, vo.map { |vo_item| [vo_item.field, vo_item.order] })
          end
        end

        if (q_page < 1) or (q_page > (q_total_records/q_page_size))
          q_page = 1
        end

        query_limit = {}
        if pagination
          query_limit.store(:limit,  q_page_size)
          query_limit.store(:offset, q_page_size * (q_page - 1))
        else
          if view_limit > 0
            query_limit.store(:limit, view_limit)
          end
        end
                                                       
        # Executes the query
      
        if the_model        
          if pagination and q_page_size >= 1
            q_total_pages = (q_total_records/q_page_size).ceil       
          end
          
          q_data = the_model.all(query.merge(query_limit))
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
    def view_conditions(arguments_values='')
    
      unless @processed_conditions 
        if not query_conditions.nil?
          @the_view_conditions = ViewQueryConditions.new(query_conditions, view_arguments, arguments_values)
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
      
      attr_reader :field, :class, :link, :image, :link_class, :image_class
      
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
        
      end
      
      def evaluate_link(element)
      
        if @link.match('element')
         eval('"'<<@link<<'"') 
        else
         @link
        end
        
      end
      
  end
    
  #
  # Represents the query conditions 
  #
  class ViewQueryConditions
    
      attr_reader :comparison, :view_arguments, :arguments_values
    
      def initialize(opts={}, v_arguments, arguments)
        @view_arguments = v_arguments
        @arguments_values = query_arguments_values(arguments)      
        @comparison = process_comparison(opts)
      end

      private 
      
      def process_comparison(opts={})
      
        if opts.has_key?('conditions') # join comparison
          process_join_comparison(opts)
        else
          process_simple_comparison(opts)
        end
      
      end
      
      def process_join_comparison(opts={})
      
        operator   = opts['operator']
        conditions = opts['conditions'].map do |condition|
                       process_comparison(condition)
                     end
        
        Conditions::JoinComparison.new(operator, conditions)
      
      end
      
      def process_simple_comparison(opts={})
      
        value = opts['value']
               
        puts "value :#{value} #{value.class.name} #{arguments_values}"       
               
        if value.kind_of?(String)
          value = value % arguments_values
          if e_m=value.match(/\{(\d+)\}/)
            value=@view_arguments[e_m[1]].typecast(value)
          end          
        else
          if value.kind_of?(Array)
            value = value.map do |element|
                      item_value = element
                      if element.kind_of?(String)
                        item_value = element % arguments_values
                        puts " -- item_value : #{item_value} element : #{element}"
                        if e_m=element.match(/\{(\d+)\}/)
                          item_value=@view_arguments[e_m[1]].typecast(item_value)
                          puts " --- item_value : #{item_value}"
                        end
                      end
                      item_value
                    end
          end
        end
        
        puts "the value :#{value}"
        
        Conditions::Comparison.new(opts['field'], opts['operator'], value )
      
      end
    
      private
    
      #
      # Extract the query argument values from the string
      #
      def query_arguments_values(arguments='')
      
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
      
      attr_reader :order, :default, :wildcard, :type
         
      def initialize(opts={})
      
        @order    = opts['order']
        @default  = opts['default']
        @wildcard = opts['wildcard']
        @type     = opts['type']
      
      end
    
      def typecast(value)
      
        return_value = case type
                         when 'integer'
                            value.to_s.to_i
                         else
                            value
                       end
              
      end
    
  end
        
end #ContentManagerSystem