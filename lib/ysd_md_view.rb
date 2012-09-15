require 'dm-types'
require 'data_mapper' 
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
    property :model_name, String, :field => 'model_name', :length => 256
    
    property :style, String, :field => 'style', :length => 10     # The style of the view
            
    property :query_fields, Json, :field => 'query_fields', :required => false
    property :query_conditions, Json, :field => 'query_conditions', :required => false
    property :query_order, Json, :field => 'query_order', :required => false
    
    property :render, String, :field => 'render', :length => 10              # The render which will be used

    property :view_limit, Integer, :field => 'view_limit', :default => 0     # To limit the number of elements to retrieve
    
    property :pagination, Boolean, :field => 'pagination', :default => false # It allow to paginate the results
    property :page_size, Integer, :field => 'page_size', :default => 0       # The page size
    
    property :data_repository, String, :field => 'data_repository', :length => 32, :default => 'default' 
    
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
    def get_data(arguments="")
                        
      the_model = (Persistence::Model.descendants.select do |model| model_name == model.model_name.downcase end).first      
      
      unless the_model
        puts "The model is not defined. Has you require it?"
      end
      
      # Build the query  
      
      #Apply args to the conditions
      args_array = query_arguments(arguments)
#      arguments ||= ''
#      args_array = arguments.split("/")
#      args_array.delete('')
#      the_query_conditions = {}
#      self.query_conditions.each do |key, value|
#        if value.kind_of?(String)
#          the_query_conditions[key] = value.to_s % args_array
#        else
#          the_query_conditions[key] = value
#        end
#      end
#      puts "the_query_conditions : #{the_query_conditions.to_json}"
      
      #context conditions
                    
#      query = {:fields => self.query_fields, :conditions => the_query_conditions, :order => self.query_order}
              
#      puts "query : #{query.to_json}"       

      query = {}
      
      #if vf=view_fields
      #  query.store(:fields, vf)
      #end
      
      if vc=view_conditions
        if the_model.included_modules.include?(DataMapper::Resource)
          query.store(:conditions, vc.comparison.build_sql)
        else
          query.store(:conditions, vc.comparison)
        end
      end
      
      if vo=view_order
      
        if the_model.included_modules.include?(DataMapper::Resource)
          query.store(:order, vo.map { |vo_item| DataMapper::Query::Operator.new(vo_item.field.to_sym, vo_item.order.to_sym) })
        else
          query.store(:order, vo.map { |vo_item| [vo_item.field, vo_item.order] })
        end
       
      end
                                     
      puts "query  : #{query.inspect}"
      puts "fields : #{view_fields}"
      puts "order  : #{view_order}"
      
      # Executes the query
            
      (the_model)?the_model.all(query):[]     
     
    end

    @processed_conditions = false
    @the_view_fields = nil
    @the_view_conditions = nil
    @the_view_order = nil
        
    #
    # Get the view fields
    #
    # @return [Array] 
    #
    #   Array of ViewQueryField
    #
    def view_fields
      
      if @the_view_fields.nil?
        @the_view_fields = []
        if not query_fields.nil? 
          query_fields.each do |query_field|
            @the_view_fields << ViewQueryField.new(query_field)
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
    def view_conditions
    
      unless @processed_conditions 
        if not query_conditions.nil?
          @the_view_conditions = ViewQueryConditions.new(query_conditions)
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
    
    private
    
    def query_arguments(arguments='')
      
      arguments ||= ''
      args_array = arguments.split("/")
      args_array.delete('')    
    
      return args_array
    
    end
    
        
  end #View        
        
  #
  # Represents a view field
  #
  class ViewQueryField
      
      attr_reader :field, :link, :image, :link_class, :image_class
      
      def initialize(opts={})
        
        puts "opts : #{opts.inspect}"
        
        @field = opts['field']

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
    
      attr_reader :comparison
    
      def initialize(opts={})
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
      
        Conditions::Comparison.new(opts['field'], opts['operator'], opts['value'])
      
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
        
end #ContentManagerSystem