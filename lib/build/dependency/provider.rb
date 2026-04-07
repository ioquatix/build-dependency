# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require_relative "set"

module Build
	module Dependency
		# Include the Provider module when Build::Dependency is included in a class.
		# @parameter klass [Class] The class that is including Build::Dependency.
		def self.included(klass)
			klass.include(Provider)
		end
		
		# A provision is a thing which satisfies a dependency.
		Provision = Struct.new(:name, :provider, :value) do
			def each_dependency(&block)
				self.provider.dependencies.each(&block)
			end
			
			def alias?
				false
			end
			
			def to_s
				"provides #{name.inspect}"
			end
		end
		
		Alias = Struct.new(:name, :provider, :dependencies) do
			def each_dependency(&block)
				return to_enum(&block) unless block_given?
				
				dependencies.each do |name|
					yield Depends.new(name)
				end
			end
			
			def alias?
				true
			end
			
			def to_s
				"provides #{name.inspect} -> #{dependencies.collect(&:inspect).join(', ')}"
			end
		end
		
		Resolution = Struct.new(:provision, :dependency) do
			def name
				dependency.name
			end
			
			def provider
				provision.provider
			end
			
			def to_s
				"resolution #{provider.name.inspect} -> #{dependency.name.inspect}"
			end
		end
		
		Depends = Struct.new(:name, :options) do
			def initialize(name, **options)
				super(name, options)
			end
			
			def wildcard?
				self.name.is_a?(String) and self.name.include?("*")
			end
			
			def match?(name)
				if wildcard? and name.is_a?(String)
					File.fnmatch?(self.name, name)
				else
					self.name == name
				end
			end
			
			def to_s
				if options.any?
					"depends on #{name.inspect} #{options.inspect}"
				else
					"depends on #{name.inspect}"
				end
			end
			
			def public?
				!!options[:public]
			end
			
			def private?
				!!options[:private]
			end
			
			def alias?
				name.is_a?(Symbol)
			end
			
			class << self
				undef []
				
				def [](name_or_dependency)
					name_or_dependency.is_a?(self) ? name_or_dependency : self.new(name_or_dependency)
				end
			end
		end
		
		# A provider that can satisfy dependencies by providing named provisions.
		module Provider
			# Freeze the provider and all its provisions and dependencies.
			def freeze
				return self if frozen?
				
				provisions.freeze
				dependencies.freeze
				
				super
			end
			
			# Assign a priority.
			def priority= value
				@priority = value
			end
			
			# The default priority.
			def priority
				@priority ||= 0
			end
			
			# @returns Hash<String, Provision> a table of named provisions.
			def provisions
				@provisions ||= {}
			end
			
			# @returns [IdentitySet<Dependency>]
			def dependencies
				@dependencies ||= Set.new
			end
			
			# Filter provisions that match a given dependency.
			# @parameter dependency [Depends] The dependency to match against.
			# @returns [Hash<String, Provision>] Provisions that match the dependency.
			def filter(dependency)
				provisions.select{|name, provision| dependency.match?(name)}
			end
			
			# Does this unit provide the named thing?
			def provides?(dependency)
				provisions.key?(dependency.name)
			end
			
			# Get the provision for a given dependency.
			# @parameter dependency [Depends] The dependency to get the provision for.
			# @returns [Provision, nil] The provision, or nil if not found.
			def provision_for(dependency)
				return provisions[dependency.name]
			end
			
			# Get a resolution for a given dependency.
			# @parameter dependency [Depends] The dependency to get the resolution for.
			# @returns [Resolution] The resolution combining the provision and dependency.
			def resolution_for(dependency)
				return Resolution.new(provision_for(dependency), dependency)
			end
			
			# Add one or more provisions to the provider.
			# @parameter names [Array<String>] the named provisions to add.
			# @parameter aliases [Hash<Symbol, Array>] the aliases to add.
			# @example A named provision.
			# 	target.provides "Compiler/clang" do
			# 		cxx "clang"
			# 	end
			# @example A symbolic provision.
			# 	target.provides compiler: "Compiler/clang"
			def provides(*names, **aliases, &block)
				names.each do |name|
					provisions[name] = Provision.new(name, self, block)
				end
				
				aliases.each do |name, dependencies|
					provisions[name] = Alias.new(name, self, Array(dependencies))
				end
			end
			
			# Add one or more dependencies to the provider.
			# @parameter names [Array<String>] the dependency names to add.
			# @example A named dependency.
			# 	target.depends "Compiler/clang"
			# @example A symbolic dependency.
			# 	target.depends :compiler
			def depends(*names, **options)
				names.each do |name|
					dependencies << Depends.new(name, **options)
				end
			end
			
			# Check if this provider depends on a given name.
			# @parameter name [String] The name to check.
			# @returns [Boolean] True if this provider depends on the given name.
			def depends?(name)
				dependencies.include?(name)
			end
		end
	end
end
