$:.push File.expand_path("../lib", __FILE__)

require "telephony/version"

Gem::Specification.new do |s|
  s.name        = "zestphone"
  s.version     = Telephony::VERSION
  s.authors     = ["Zest"]
  s.homepage    = "https://github.com/ZestFinance/zestphone"
  s.summary     = "Call placing and handling framework."
  s.description = "Call placing and handling framework."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.0"
  s.add_dependency "state_machine"
  s.add_dependency "kaminari"
  s.add_dependency "pusher", "0.11.3"
  s.add_dependency "ejs"
  s.add_dependency "sass"
end
