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

require_relative 'chain'

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
				
				# The list of dependencies that needs to be satisfied:
				@dependencies = dependencies.collect{|dependency| Depends[dependency]}
				
				expand_top
			end
			
			def selection
				@chain.selection
			end
			
			attr :dependencies
			
			def providers
				@chain.providers
			end
			
			def freeze
				return unless frozen?
				
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
			
			def find_provider(dependency, parent)
				if provider = @chain.resolved[dependency]
					yield provider
					return true
				end
				
				return false
			end
			
			def provision_for(provider, dependency)
				# @chain.resolved[provider] does work, but it points to the most recently added provision, but we want the provision related to the specific dependency.
				provider.provision_for(dependency)
			end
		end
	end
end
