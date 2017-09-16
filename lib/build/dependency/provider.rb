# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'set'

module Build
	module Dependency
		def self.included(klass)
			klass.include(Provider)
		end
		
		# A provision is a thing which satisfies a dependency.
		Provision = Struct.new(:name, :provider, :value) do
			def alias?
				false
			end
			
			def to_s
				"provides #{name.inspect}"
			end
		end
		
		Alias = Struct.new(:name, :provider, :dependencies) do
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
		
		Depends = Struct.new(:name) do
			def initialize(name, **options)
				super(name)
				
				@options = options
			end
			
			def wildcard?
				self.name.is_a?(String) and self.name.include?('*')
			end
			
			def match?(name)
				if wildcard? and name.is_a?(String)
					File.fnmatch?(self.name, name)
				else
					self.name == name
				end
			end
			
			attr :options
			
			def to_s
				if @options.any?
					"depends on #{name.inspect} #{@options.inspect}"
				else
					"depends on #{name.inspect}"
				end
			end
			
			def private?
				@options[:private]
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
		
		module Provider
			def freeze
				return unless frozen?
				
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
			
			# @return Hash<String, Provision> a table of named provisions.
			def provisions
				@provisions ||= {}
			end
			
			# @return Set<Dependency>
			def dependencies
				@dependencies ||= Set.new
			end
			
			def filter(dependency)
				provisions.select{|key,value| dependency.match?(key)}
			end
			
			# Does this unit provide the named thing?
			def provides?(dependency)
				provisions.key?(dependency.name)
			end
			
			def provision_for(dependency)
				return provisions[dependency.name]
			end
			
			def resolution_for(dependency)
				return Resolution.new(provision_for(dependency), dependency)
			end
			
			# Add one or more provisions to the provider.
			# @param [Array<String>] names the named provisions to add.
			# @param [Hash<Symbol, Array>] aliases the aliases to add.
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
			# @param [Array<String>] names the dependency names to add.
			# @example A named dependency.
			# 	target.depends "Compiler/clang"
			# @example A symbolic dependency.
			# 	target.depends :compiler
			def depends(*names, **options)
				names.each do |name|
					dependencies << Depends.new(name, **options)
				end
			end
			
			def depends?(name)
				dependencies.include?(name)
			end
		end
	end
end
