# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2019, by Samuel Williams.

require_relative "chain"

module Build
	module Dependency
		class Chain
			def partial(provider)
				PartialChain.expand(self, provider.dependencies)
			end
		end
		
		class PartialChain < Resolver
			# An `UnresolvedDependencyError` will be thrown if there are any unresolved dependencies.
			def self.expand(*args)
				chain = self.new(*args)
				
				chain.freeze
				
				return chain
			end
			
			def initialize(chain, dependencies)
				super()
				
				@chain = chain
				
				@dependencies = dependencies.collect{|dependency| Depends[dependency]}
				
				expand_top
			end
			
			def selection
				@chain.selection
			end
			
			# @attr [Array<Depends>] The list of dependencies that needs to be satisfied.
			attr :dependencies
			
			def providers
				@chain.providers
			end
			
			def freeze
				return self if frozen?
				
				@chain.freeze
				@dependencies.freeze
				
				super
			end
			
			protected
			
			def expand_top
				expand_nested(@dependencies, TOP)
			end
			
			def expand(dependency, parent)
				unless @dependencies.include?(dependency)
					return if dependency.private?
				end
				
				super(dependency, parent)
			end
			
			def expand_dependency(dependency, parent)
				@chain.resolved[dependency]
			end
			
			def provision_for(provider, dependency)
				# @chain.resolved[provider] does work, but it points to the most recently added provision, but we want the provision related to the specific dependency.
				provider.provision_for(dependency)
			end
		end
	end
end
