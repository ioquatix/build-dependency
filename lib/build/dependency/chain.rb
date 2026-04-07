# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require_relative "resolver"

require "set"

module Build
	module Dependency
		# A chain of dependencies that are resolved from a set of providers.
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
			
			# Initialize a dependency chain.
			# @parameter dependencies [Array<String, Depends>] The dependencies to resolve.
			# @parameter providers [Array<Provider>] The providers to use for resolution.
			# @parameter selection [Array<String>] Explicitly selected dependencies for resolving ambiguity.
			def initialize(dependencies, providers, selection = [])
				super()
				
				@selection = ::Set.new(selection)
				@dependencies = dependencies.collect{|dependency| Depends[dependency]}
				@providers = providers
				
				expand_top
			end
			
			# @attr [Set<String>] Explicitly selected dependencies which will be used when resolving ambiguity.
			attr :selection
			
			# @attr [Array<Depends>] The list of dependencies that needs to be satisfied.
			attr :dependencies
			
			# @attr [Array] The available providers which will be used to satisfy he required dependencies.
			attr :providers
			
			# Freeze the chain and all its dependencies.
			def freeze
				return self if frozen?
				
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
			
			# Given a dependency with wildcards, figure out all names that might match, and then expand them all individually.
			def expand_wildcard(dependency, parent)
				@providers.flat_map do |provider|
					provider.filter(dependency).flat_map do |name, provision|
						expand_dependency(Depends[name], parent)
					end
				end
			end
			
			# Resolve a dependency into one or more provisions.
			def expand_dependency(dependency, parent)
				# The job of this function is to take a dependency and turn it into 0 or more provisions. The dependency could be a normal fully-qualified name or a wildcard. It's not clear at which point pattern matching should affect dependency resolution, but it seems logical since it depends on the available provisions that it's done here.
				# Another benefit is that it introduces a fixed point of reference for expanding dependencies. When the resolver invokes this method, it can be assured that it will return the same result.
				if dependency.wildcard?
					return expand_wildcard(dependency, parent)
				end
				
				# Mostly, only one package will satisfy the dependency...
				viable_providers = @providers.select{|provider| provider.provides? dependency}
				
				# puts "** Found #{viable_providers.collect(&:name).join(', ')} viable providers."
				
				if viable_providers.size == 1
					provider = viable_providers.first
					provision = provision_for(provider, dependency)
					
					# The best outcome, a specific provider was named:
					return [provision]
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
						return [provision]
					else
						# Multiple providers were explicitly mentioned that satisfy the dependency.
						@conflicts[dependency] = explicit_providers
					end
				end
				
				return []
			end
			
			def provision_for(provider, dependency)
				provider.provision_for(dependency)
			end
		end
	end
end
