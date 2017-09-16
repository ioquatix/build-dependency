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
				# puts "** Expanding #{dependency.inspect} from #{parent.inspect} (private: #{dependency.private?})"
				
				if @resolved.include?(dependency)
					# puts "** Already resolved dependency!"
					
					return nil
				end
				
				# The find_provider method is abstract in this base class.
				provisions = expand_dependency(dependency, parent)
				
				if provisions.empty?
					# puts "** Couldn't resolve #{dependency}"
					@unresolved << [dependency, parent]
				else
					# We will now satisfy this dependency by satisfying any dependent dependencies, but we no longer need to revisit this one.
					# puts "** Resolved #{dependency}"
					@resolved[dependency] = provisions
					
					provisions.each do |provision|
						expand_provision(provision, dependency)
					end
				end
			end
		end
	end
end
