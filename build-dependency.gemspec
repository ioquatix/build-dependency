# frozen_string_literal: true

require_relative "lib/build/dependency/version"

Gem::Specification.new do |spec|
	spec.name = "build-dependency"
	spec.version = Build::Dependency::VERSION
	
	spec.summary = "A set of data structures and algorithms for dependency resolution."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.files = Dir.glob(["{lib,test}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.3"
	
	spec.add_dependency "graphviz"
end
