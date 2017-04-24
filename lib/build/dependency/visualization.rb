# Copyright, 20127, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'graphviz'

module Build
	module Dependency
		class Visualization
			def initialize
				@base_attributes = {
					:shape => 'box',
					:style => 'filled',
					:fillcolor => 'white',
					:fontname => 'Monaco',
				}
				
				@provision_attributes = @base_attributes.dup
				
				@alias_attributes = @base_attributes.merge(
					:fillcolor => 'lightgrey',
				)
				
				@target_attributes = @base_attributes.merge(
					:fillcolor => 'orange',
				)
				
				@selection_attributes = {
					:fillcolor => 'lightbrown',
				}
				
				@private_edge_attributes = {
					:arrowhead => 'empty',
					:color => '#0000005f'
				}
				
				@provider_attributes = {
					:fillcolor => 'lightblue',
				}
				
				@provider_edge_attributes = {
					:arrowhead => 'none',
				}
			end
			
			attr :base_attributes
			attr :provision_attributes
			
			attr :provider_attributes
			attr :provider_edge_attributes
			
			attr :alias_attributes
			
			attr :target_attributes
			attr :selection_attributes
			attr :private_edge_attributes
			
			def generate(chain)
				graph = Graphviz::Graph.new
				graph.attributes[:ratio] = :auto
				
				chain.ordered.each do |resolution|
					provider = resolution.provider
					name = provider.name
					
					# Provider is the target that provides the target referred to by name.
					node = graph.add_node(name.to_s, @base_attributes.dup)
					
					if chain.targets.include?(resolution.target)
						node.attributes.update(@target_attributes)
					elsif chain.selection.include?(provider.name)
						node.attributes.update(@selection_attributes)
					end
					
					# A provision has targets...
					provider.targets.each do |target|
						if target_node = graph.nodes[target.name.to_s]
							edge = node.connect(target_node)
							
							if target.private?
								edge.attributes.update(@private_edge_attributes)
							end
						end
					end
					
					# A provision provides other provisions...
					provider.provisions.each do |provision_name, provision|
						next if name == provision_name
						
						provides_node = graph.nodes[provision_name.to_s] || graph.add_node(provision_name.to_s, @provision_attributes)
						
						if Dependency::Alias === provision
							provides_node.attributes = @alias_attributes
						end
						
						node.attributes.update(@provider_attributes)
						
						unless provides_node.connected?(node)
							edge = provides_node.connect(node)
							
							edge.attributes.update(@provider_edge_attributes)
						end
					end
				end
				
				# Put all targets at the same level so as to not make the graph too confusingraph.
				done = Set.new
				chain.ordered.each do |resolution|
					provider = resolution.provider
					name = "subgraph-#{provider.name}"
					
					subgraph = graph.nodes[name] || graph.add_subgraph(name, :rank => :same)
					
					provider.targets.each do |target|
						next if done.include? target
						
						done << target
						
						if target_node = graph.nodes[target.name.to_s]
							subgraph.add_node(target_node.name)
						end
					end
				end
				
				return graph
			end
		end
	end
end