# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.

require "forwardable"

module Build
	module Dependency
		# Very similar to a set but uses a specific callback (defaults to &:name) for object identity.
		class Set
			include Enumerable
			
			# Initialize a new set with optional initial contents.
			# @parameter contents [Array] Initial objects to add to the set.
			def initialize(contents = [])
				@table = {}
				
				contents.each do |object|
					add(object)
				end
			end
			
			attr :table
			
			extend Forwardable
			
			def_delegators :@table, :size, :empty?, :clear, :count, :[], :to_s, :inspect
			
			# Freeze the set.
			def freeze
				return self if frozen?
				
				@table.freeze
				
				super
			end
			
			# Initialize a duplicate of another set.
			# @parameter other [Set] The set to duplicate.
			def initialize_dup(other)
				@table = other.table.dup
			end
			
			# Get the identity of an object for use as a hash key.
			# @parameter object [Object] The object to get the identity for.
			# @returns [String] The object's name.
			def identity(object)
				object.name
			end
			
			# Add an object to the set.
			# @parameter object [Object] The object to add.
			# @raises [KeyError] If an object with the same identity already exists.
			def add(object)
				if include?(object)
					raise KeyError, "Object #{identity(object)} already exists!"
				end
				
				@table[identity(object)] = object
			end
			
			alias << add
			
			# Delete an object from the set.
			# @parameter object [Object] The object to delete.
			# @returns [Object, nil] The deleted object, or nil if not found.
			def delete(object)
				@table.delete(identity(object))
			end
			
			# Check if the set includes an object.
			# @parameter object [Object] The object to check for.
			# @returns [Boolean] True if the set includes the object.
			def include?(object)
				@table.include?(identity(object))
			end
			
			# Iterate over each object in the set.
			# @yields [Object] Each object in the set.
			def each(&block)
				@table.each_value(&block)
			end
			
			# Get a subset of objects by their names.
			# @parameter names [Array<String>] The names of objects to retrieve.
			# @returns [Array<Object>] The objects with the given names.
			def slice(names)
				names.collect{|name| @table[name]}
			end
		end
	end
end
