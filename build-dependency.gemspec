# coding: utf-8
require_relative 'lib/build/dependency/version'

Gem::Specification.new do |spec|
	spec.name          = "build-dependency"
	spec.version       = Build::Dependency::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]
	spec.summary       = %q{A nested hash data structure for controlling build dependencys.}
	spec.homepage      = ""
	spec.license       = "MIT"

	spec.files         = `git ls-files -z`.split("\x0")
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
	spec.require_paths = ["lib"]
	
	spec.add_dependency "graphviz"
	
	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rspec", "~> 3.4.0"
	spec.add_development_dependency "rake"
end
