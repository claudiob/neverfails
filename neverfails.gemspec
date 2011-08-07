# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'neverfails'
  s.version     = '0.0.3'
  s.authors       = ["Claudio B."]
  s.email         = ["claudiob@gmail.com"]
  s.homepage      = "https://github.com/claudiob/neverfails/tree/rails"
  s.summary       = %q{Cucumber plugin that generates code to make failing steps pass}
  s.description   = %q{With neverfails, step definitions do not simply check whether the existing code satifies the required behaviour or not. They also write the code to make them pass.}
  s.licenses      = ["MIT"]

  s.add_dependency 'cucumber'
  s.add_dependency 'cucumber-rails'

  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_path     = "lib"
end
