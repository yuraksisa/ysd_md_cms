Gem::Specification.new do |s|
  s.name    = "ysd_md_cms"
  s.version = "0.2.42"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2011-08-23"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb']
  s.summary = "Yurak Sisa Content Manager System model"
  s.homepage = "http://github.com/yuraksisa/ysd_md_cms"  
  
  s.add_runtime_dependency "data_mapper", "1.2.0"
  s.add_runtime_dependency "uuid", "2.3.5"        # UUID generator
  s.add_runtime_dependency "unicode_utils"        # Unicode Utils

  s.add_runtime_dependency "ysd_md_yito"          # Yito model base
  s.add_runtime_dependency "ysd-persistence"      # Persistence system
  s.add_runtime_dependency "ysd_md_comparison"    # Comparison
  s.add_runtime_dependency "ysd_md_profile"       # Block permissions
  s.add_runtime_dependency "ysd_md_audit"         # Audit (content)
  s.add_runtime_dependency "ysd_md_rac"           # Resource Access Control (content)
  s.add_runtime_dependency "ysd_md_translation"   # Translation
  s.add_runtime_dependency "ysd_md_system"        # System
  s.add_runtime_dependency "ysd_md_search"        # Search engine   
  s.add_runtime_dependency "ysd_core_plugins"     # Plugins (content type aspects)
  s.add_runtime_dependency "ysd_data_analysis"    # Data Analysis

  
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "dm-sqlite-adapter" # Model testing using sqlite

end
