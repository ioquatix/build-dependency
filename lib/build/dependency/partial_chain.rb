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
			def partial(targets)
				PartialChain.expand(self, targets)
			end
		end
		
		class PartialChain < Resolver
			# An `UnresolvedDependencyError` will be thrown if there are any unresolved targets.
			def self.expand(*args)
				chain = self.new(*args)
				
				chain.freeze
				
				return chain
			end
			
			def initialize(chain, targets)
				super()
				
				@chain = chain
				
				# The list of targets that needs to be satisfied:
				@targets = targets.collect{|target| Target[target]}
				
				# This is a list of all top level providers. We will expand all children of these packages, but we will ignore private targets of any others.
				@top = @targets.map{|target| @chain.resolved[target]}
				
				expand_top
			end
			
			def selection
				@chain.selection
			end
			
			attr :targets
			
			def providers
				@chain.providers
			end
			
			def freeze
				return unless frozen?
				
				@chain.freeze
				@targets.freeze
				
				super
			end
			
			protected
			
			def expand_top
				expand_nested(@targets, TOP)
			end
			
			def expand(target, parent)
				unless @top.include?(parent)
					return if target.private?
				end
				
				super(target, parent)
			end
			
			def find_provider(target, parent)
				@chain.resolved[target]
			end
			
			def provision_for(provider, target)
				# @chain.resolved[provider] does work, but it points to the most recently added provision, but we want the provision related to the specific target.
				provider.provision_for(target)
			end
		end
	end
end
