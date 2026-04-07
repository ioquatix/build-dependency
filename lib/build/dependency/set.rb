# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019, by Samuel Williams.

require "forwardable"

module Build
	module Dependency
		# Very similar to a set but uses a specific callback (defaults to &:name) for object identity.
		class Set
			include Enumerable
			
			def initialize(contents = [])
				@table = {}
				
				contents.each do |object|
					add(object)
				end
			end
			
			attr :table
			
			extend Forwardable
			
			def_delegators :@table, :size, :empty?, :clear, :count, :[], :to_s, :inspect
			
			def freeze
				return self if frozen?
				
				@table.freeze
				
				super
			end
			
			def initialize_dup(other)
				@table = other.table.dup
			end
			
			def identity(object)
				object.name
			end
			
			def add(object)
				if include?(object)
					raise KeyError, "Object #{identity(object)} already exists!"
				end
				
				@table[identity(object)] = object
			end
			
			alias << add
			
			def delete(object)
				@table.delete(identity(object))
			end
			
			def include?(object)
				@table.include?(identity(object))
			end
			
			def each(&block)
				@table.each_value(&block)
			end
			
			def slice(names)
				names.collect{|name| @table[name]}
			end
		end
	end
end
