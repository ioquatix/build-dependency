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
			klass.include(Unit)
		end
		
		Provision = Struct.new(:value)
		
		Alias = Struct.new(:dependencies)
		
		Resolution = Struct.new(:provider, :name)
		
		# # A query against the set of available provisions, e.g.
		# # Target.new('package-name', version: '>= 3.0.0')
		# Target = Struct.new(:name, :options)
		# 
		# Depends = Struct.new(:name) do
		# 	def initialize(name, **options)
		# 		super(name)
		# 		@options = options
		# 	end
		# 	
		# 	attr :options
		# 	
		# 	def private?
		# 		@options[:private]
		# 	end
		# end
		# 
		module Unit
			def freeze
				return unless frozen?
				
				provisions.freeze
				dependencies.freeze
				
				super
			end
			
			# Assign a priority to this unit.
			def priority= value
				@priority = value
			end
			
			# The units default priority
			def priority
				@priority ||= 0
			end
			
			# @return Hash<String, Provision> a hash of named provisions.
			def provisions
				@provisions ||= {}
			end
			
			# @return Set<Dependency>
			def dependencies
				@dependencies ||= Set.new
			end
			
			# Does this unit provide the named thing?
			def provides?(name)
				provisions.key? name
			end
			
			# Mark this unit as providing the named thing, with an optional block.
			def provides(name_or_aliases, &block)
				if String === name_or_aliases || Symbol === name_or_aliases
					name = name_or_aliases
					
					provisions[name] = Provision.new(block)
				else
					aliases = name_or_aliases
					
					aliases.each do |name, dependencies|
						provisions[name] = Alias.new(Array(dependencies))
					end
				end
			end
			
			def depends(name, **options)
				dependencies << name # Depends.new(name, **options)
			end
			
			def depends?(name)
				dependencies.include? name
			end
		end
	end
end
