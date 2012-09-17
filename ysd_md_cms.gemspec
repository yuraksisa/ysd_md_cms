Gem::Specification.new do |s|
  s.name    = "ysd_md_cms"
  s.version = "0.2.0"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2011-08-23"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb']
  s.summary = "Yurak Sisa Content Manager System model"
  s.homepage = "http://github.com/yuraksisa/ysd_md_cms"  
  
  s.add_runtime_dependency "data_mapper", "1.1.0"
  s.add_runtime_dependency "dm-types", "1.1.0"    # View JSON field
  
  s.add_runtime_dependency "ysd-persistence"      # Persistence system
  s.add_runtime_dependency "ysd_md_comparison"    # Comparison
  s.add_runtime_dependency "ysd_md_audit"         # Audit information
  s.add_runtime_dependency "ysd_md_profile"       # Profiles 
  s.add_runtime_dependency "ysd_core_plugins"     # Plugins
  
end
