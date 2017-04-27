
if ENV['COVERAGE'] || ENV['TRAVIS']
	begin
		require 'simplecov'
		
		SimpleCov.start do
			add_filter "/spec/"
		end
		
		if ENV['TRAVIS']
			require 'coveralls'
			Coveralls.wear!
		end
	rescue LoadError
		warn "Could not load simplecov: #{$!}"
	end
end

require "bundler/setup"
require "build/dependency"

class Package
	include Build::Dependency
	
	def initialize(name = nil)
		@name = name
	end
	
	attr :name
	
	def inspect
		"<Package:#{@name}>"
	end
end

RSpec.shared_context "app packages" do
	let(:app) do
		Package.new('app').tap do |package|
			package.provides 'app'
			package.depends 'lib', private: true
			package.depends :platform, private: true
			package.depends 'Language/C++14', private: true
		end
	end
	
	let(:tests) do
		Package.new('tests').tap do |package|
			package.provides 'tests'
			package.depends 'lib', private: true
			package.depends :platform, private: true
			package.depends 'Language/C++17', private: true
		end
	end
	
	let(:lib) do
		Package.new('lib').tap do |package|
			package.provides 'lib'
			package.depends :platform, private: true
			package.depends 'Language/C++17', private: true
		end
	end
	
	let(:platform) do
		Package.new('Platform/linux').tap do |package|
			package.provides platform: 'Platform/linux'
			package.provides 'Platform/linux'
			package.depends :variant
		end
	end
	
	let(:variant) do
		Package.new('Variant/debug').tap do |package|
			package.provides variant: 'Variant/debug'
			package.provides 'Variant/debug'
		end
	end
	
	let(:compiler) do
		Package.new('Compiler/clang').tap do |package|
			package.provides 'Language/C++14'
			package.provides 'Language/C++17'
		end
	end
	
	let(:packages) {[app, tests, lib, platform, variant, compiler]}
	
	let(:visualization) {Build::Dependency::Visualization.new}
end

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
