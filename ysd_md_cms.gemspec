Gem::Specification.new do |s|
  s.name    = "ysd_md_cms"
  s.version = "0.1"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2011-08-23"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb']
  s.summary = "Yurak Sisa Content Manager System model"
  
  s.add_runtime_dependency "ysd-persistence"
  s.add_runtime_dependency "ysd_md_auditory"
end
