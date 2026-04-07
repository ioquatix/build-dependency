# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require "build/dependency"

module Build
	module DependencyContext
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
		
		module AppPackages
			def app
				@app ||= Package.new("app").tap do |package|
					package.provides "app"
					package.depends "lib", private: true
					package.depends :platform, private: true
					package.depends "Language/C++14", private: true
				end
			end
			
			def tests
				@tests ||= Package.new("tests").tap do |package|
					package.provides "tests"
					package.depends "lib", private: true
					package.depends :platform, private: true
					package.depends "Language/C++17", private: true
				end
			end
			
			def lib
				@lib ||= Package.new("lib").tap do |package|
					package.provides "lib"
					package.depends :platform, private: true
					package.depends "Language/C++17", private: true
				end
			end
			
			def platform
				@platform ||= Package.new("Platform/linux").tap do |package|
					package.provides platform: "Platform/linux"
					package.provides "Platform/linux"
					package.depends :variant
				end
			end
			
			def variant
				@variant ||= Package.new("Variant/debug").tap do |package|
					package.provides variant: "Variant/debug"
					package.provides "Variant/debug"
				end
			end
			
			def compiler
				@compiler ||= Package.new("Compiler/clang").tap do |package|
					package.provides "Language/C++14"
					package.provides "Language/C++17"
				end
			end
			
			def packages
				[app, tests, lib, platform, variant, compiler]
			end
			
			def visualization
				@visualization ||= Build::Dependency::Visualization.new
			end
		end
	end
end
