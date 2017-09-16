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
		class UnresolvedDependencyError < StandardError
			def initialize(chain)
				super "Unresolved dependency chain: #{chain.unresolved.inspect}!"
				
				@chain = chain
			end
			
			attr :chain
		end
		
		TOP = Depends.new("<top>").freeze
		
		class Resolver
			def initialize
				@resolved = {}
				@ordered = []
				@provisions = []
				@unresolved = []
				@conflicts = {}
			end
			
			attr :resolved
			attr :ordered
			attr :provisions
			attr :unresolved
			attr :conflicts
			
			def freeze
				return unless frozen?
				
				@resolved.freeze
				@ordered.freeze
				@provisions.freeze
				@unresolved.freeze
				@conflicts.freeze
				
				super
			end
			
			protected
			
			def expand_nested(dependencies, provider)
				dependencies.each do |dependency|
					expand(Depends[dependency], provider)
				end
			end
			
			def expand_provider(provider, dependency, parent)
				# We will now satisfy this dependency by satisfying any dependent dependencies, but we no longer need to revisit this one.
				# puts "** Resolved #{dependency} (#{provision.inspect})"
				@resolved[dependency] = provider
				
				provision = provision_for(provider, dependency)
				
				expand_provision(provision, dependency)
			end
			
			def expand_provision(provision, dependency)
				provider = provision.provider
				
				# If the provision was an Alias, make sure to resolve the alias first:
				if provision.alias?
					# puts "** Resolving alias #{provision} (#{provision.dependencies.inspect})"
					expand_nested(provision.dependencies, provider)
				end
				
				# puts "** Checking for #{provider.inspect} in #{resolved.inspect}"
				unless @resolved.include?(provider)
					# We are now satisfying the provider by expanding all its own dependencies:
					@resolved[provider] = provision
					
					# Make sure we satisfy the provider's dependencies first:
					expand_nested(provider.dependencies, provider)
					
					# puts "** Appending #{dependency} -> ordered"
					
					# Add the provider to the ordered list.
					@ordered << Resolution.new(provision, dependency)
				end
				
				# This goes here because we want to ensure 1/ that if 
				unless provision == nil or provision.alias?
					# puts "** Appending #{dependency} -> provisions"
					
					# Add the provision to the set of required provisions.
					@provisions << provision
				end
				
				# For both @ordered and @provisions, we ensure that for [...xs..., x, ...], x is satisfied by ...xs....
			end
			
			def expand(dependency, parent)
				puts "** Expanding #{dependency.inspect} from #{parent.inspect} (private: #{dependency.private?})"
				
				if @resolved.include?(dependency)
					puts "** Already resolved dependency!"
					
					return nil
				end
				
				# The find_provider method is abstract in this base class.
				expand_dependency(dependency, parent) do |provision|
					# We will now satisfy this dependency by satisfying any dependent dependencies, but we no longer need to revisit this one.
					# puts "** Resolved #{dependency} (#{provision.inspect})"
					@resolved[dependency] = provision
					
					expand_provision(provision, dependency)
				end or begin
					puts "** Couldn't find_provider(#{dependency}, #{parent}) -> unresolved"
					@unresolved << [dependency, parent]
				end
			end
		end
		
		class Chain < Resolver
			# An `UnresolvedDependencyError` will be thrown if there are any unresolved dependencies.
			def self.expand(*args)
				chain = self.new(*args)
				
				chain.freeze
				
				if chain.unresolved.size > 0
					raise UnresolvedDependencyError.new(chain)
				end
				
				return chain
			end
			
			def initialize(dependencies, providers, selection = [])
				super()
				
				# Explicitly selected dependencies which will be used when resolving ambiguity:
				@selection = Set.new(selection)
				
				# The list of dependencies that needs to be satisfied:
				@dependencies = dependencies.collect{|dependency| Depends[dependency]}
				
				# The available providers which match up to required dependencies:
				@providers = providers
				
				expand_top
			end
			
			attr :selection
			attr :dependencies
			attr :providers
			
			def freeze
				return unless frozen?
				
				@selection.freeze
				@dependencies.freeze
				@providers.freeze
				
				super
			end
			
			protected
			
			def expand_top
				# puts "Expanding #{@dependencies.inspect}"
				
				expand_nested(@dependencies, TOP)
			end
			
			def filter_by_priority(viable_providers)
				# Sort from highest priority to lowest priority:
				viable_providers = viable_providers.sort{|a,b| b.priority <=> a.priority}
				
				# The first item has the highest priority:
				highest_priority = viable_providers.first.priority
				
				# We compute all providers with the same highest priority (may be zero):
				return viable_providers.take_while{|provider| provider.priority == highest_priority}
			end
			
			def filter_by_selection(viable_providers)
				return viable_providers.select{|provider| @selection.include? provider.name}
			end
			
			def expand_dependency(dependency, parent)
				# Mostly, only one package will satisfy the dependency...
				viable_providers = @providers.select{|provider| provider.provides? dependency}
				
				puts "** Found #{viable_providers.collect(&:name).join(', ')} viable providers."
				
				if viable_providers.size == 1
					provider = viable_providers.first
					provision = provision_for(provider, dependency)
					
					# The best outcome, a specific provider was named:
					yield provision
					
					return true
				elsif viable_providers.size > 1
					# ... however in some cases (typically where aliases are being used) an explicit selection must be made for the build to work correctly.
					explicit_providers = filter_by_selection(viable_providers)
					
					# puts "** Filtering to #{explicit_providers.collect(&:name).join(', ')} explicit providers."
					
					if explicit_providers.size != 1
						# If we were unable to select a single package, we may use the priority to limit the number of possible options:
						explicit_providers = viable_providers if explicit_providers.empty?
						
						explicit_providers = filter_by_priority(explicit_providers)
					end
					
					if explicit_providers.size == 0
						# No provider was explicitly specified, thus we require explicit conflict resolution:
						@conflicts[dependency] = viable_providers
					elsif explicit_providers.size == 1
						provider = explicit_providers.first
						provision = provision_for(provider, dependency)
						
						# The best outcome, a specific provider was named:
						yield provision
						
						return true
					else
						# Multiple providers were explicitly mentioned that satisfy the dependency.
						@conflicts[dependency] = explicit_providers
					end
				end
				
				return false
			end
			
			def provision_for(provider, dependency)
				provider.provision_for(dependency)
			end
		end
	end
end
