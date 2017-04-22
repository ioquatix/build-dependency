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
				super "Unresolved target chain!"
				
				@chain = chain
			end
			
			attr :chain
		end
		
		class Chain
			# An `UnresolvedDependencyError` will be thrown if there are any unresolved targets.
			def self.expand(*args)
				chain = self.new(*args)
				
				chain.freeze
				
				if chain.unresolved.size > 0
					raise UnresolvedDependencyError.new(chain)
				end
				
				return chain
			end
			
			TOP = Target.new("<top>").freeze
			
			def initialize(selection, targets, providers)
				# Explicitly selected targets which will be used when resolving ambiguity:
				@selection = Set.new(selection)
				
				# The list of targets that needs to be satisfied:
				@targets = targets
				
				# The available providers which match up to required targets:
				@providers = providers
				
				@resolved = Set.new
				@ordered = []
				@provisions = []
				@unresolved = []
				@conflicts = {}
				
				@parent = Target.new("<top>")
				
				expand_all
			end
			
			attr :selection
			attr :targets
			attr :providers
			
			attr :resolved
			attr :ordered
			attr :provisions
			attr :unresolved
			attr :conflicts
			
			def freeze
				return unless frozen?
				
				@selection.freeze
				@targets.freeze
				@providers.freeze
				
				@resolved.freeze
				@ordered.freeze
				@provisions.freeze
				@unresolved.freeze
				@conflicts.freeze
				
				super
			end
			
			private
			
			def expand?(target)
				# puts "Should I expand target: #{target} - it's #{target.private? ? 'private' : 'not private'} and #{@targets.include?(target) ? 'in' : 'not in'} @targets"
				
				!target.private? || @targets.include?(target)
			end
			
			def expand_all(targets = @targets, parent = TOP, force = true)
				targets.each do |target|
					expand(Target[target], parent, force)
				end
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
			
			def find_provider(target, parent)
				# Mostly, only one package will satisfy the target...
				viable_providers = @providers.select{|provider| provider.provides? target}
				
				# puts"** Found #{viable_providers.collect(&:name).join(', ')} viable providers."
				
				if viable_providers.size > 1
					# ... however in some cases (typically where aliases are being used) an explicit selection must be made for the build to work correctly.
					explicit_providers = filter_by_selection(viable_providers)
					
					# puts"** Filtering to #{explicit_providers.collect(&:name).join(', ')} explicit providers."
					
					if explicit_providers.size != 1
						# If we were unable to select a single package, we may use the priority to limit the number of possible options:
						explicit_providers = viable_providers if explicit_providers.empty?
						
						explicit_providers = filter_by_priority(explicit_providers)
					end
					
					if explicit_providers.size == 0
						# No provider was explicitly specified, thus we require explicit conflict resolution:
						@conflicts[target] = viable_providers
						return nil
					elsif explicit_providers.size == 1
						# The best outcome, a specific provider was named:
						return explicit_providers.first
					else
						# Multiple providers were explicitly mentioned that satisfy the target.
						@conflicts[target] = explicit_providers
						return nil
					end
				else
					return viable_providers.first
				end
			end
			
			def expand(target, parent, force)
				return unless force || expand?(target)
				
				# puts "** Expanding #{target} from #{parent}"
				
				if @resolved.include?(target)
					# puts"** Already resolved target!"
					
					return
				end
				
				provider = find_provider(target, parent)
				
				if provider == nil
					# puts"** Couldn't find provider -> unresolved"
					@unresolved << [target, parent]
					return nil
				end
				
				provision = provider.provision_for(target)
				
				# We will now satisfy this target by satisfying any dependent targets, but we no longer need to revisit this one.
				# puts"** Resolved #{target} (#{provision.inspect})"
				@resolved << target
				
				# If the provision was an Alias, make sure to resolve the alias first:
				if Alias === provision
					# puts"** Resolving alias #{provision} (#{provision.targets.inspect})"
					
					# We force expand all children of any top level target:
					# TODO: While this works, it feels a bit messy.
					expand_all(provision.targets, provider, parent.equal?(TOP))
				end
				
				# puts"** Checking for #{provider.inspect} in #{resolved.inspect}"
				unless @resolved.include?(provider)
					# We are now satisfying the provider by expanding all its own targets:
					@resolved << provider
					
					# Make sure we satisfy the provider's targets first:
					expand_all(provider.targets, provider, parent.equal?(TOP))
					
					# puts"** Appending #{target} -> ordered"
					
					# Add the provider to the ordered list.
					@ordered << Resolution.new(provider, target)
				end
				
				# This goes here because we want to ensure 1/ that if 
				unless provision == nil or Alias === provision
					# puts"** Appending #{target} -> provisions"
					
					# Add the provision to the set of required provisions.
					@provisions << provision
				end
				
				# For both @ordered and @provisions, we ensure that for [...xs..., x, ...], x is satisfied by ...xs....
			end
		end
	end
end
