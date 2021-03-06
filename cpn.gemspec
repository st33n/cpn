# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cpn/version"

Gem::Specification.new do |s|
  s.name        = "cpn"
  s.version     = CPN::VERSION
  s.authors     = ["Steen Lehmann", "Craig Taverner"]
  s.email       = ["steen.lehmann@gmail.com", "craig@amanzi.com"]
  s.homepage    = ""
  s.summary     = %q{Coloured Petri Nets for Ruby}
  s.description = %q{Coloured Petri Net implementation for Ruby}

#  s.rubyforge_project = "cpn"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  # s.add_runtime_dependency "rest-client"
end

