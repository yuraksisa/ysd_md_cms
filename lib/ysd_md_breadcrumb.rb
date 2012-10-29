module Site
  
  #
  # It represents the breadcrumb
  #
  # bc = Breadcrumb.new()
  # bc.unshift({:path => '/mydocs', :title => 'My docs'})
  # bc.unshift({:path => '/', :title => 'Home'})
  #
  # It holds an array of hashes. Each hash has the following keys:
  #
  #  :title
  #  :path
  #
  class Breadcrumb < Array
                  
  end#Breadcrumb
end#Site    