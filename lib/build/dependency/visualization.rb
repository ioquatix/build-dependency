# frozen_string_literal: true

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

module Build
	module Dependency
		class Visualization
			def sanitize_id(name)
				# Convert name to a valid Mermaid node ID
				name.to_s.gsub(/[^a-zA-Z0-9_]/, "_")
			end
			
			def generate(chain)
				lines = ["flowchart LR"]
				
				# Track nodes and their styles
				nodes = {}
				providers = ::Set.new
				provisions_in_chain = ::Set.new
				
				# Collect all provisions in the chain
				chain.provisions.each do |provision|
					provisions_in_chain.add(provision.name.to_s)
				end
				
				# Build the graph
				chain.ordered.each do |resolution|
					provider = resolution.provider
					name = provider.name.to_s
					node_id = sanitize_id(name)
					
					# Track this node
					nodes[name] = node_id
					
					# A provision has dependencies...
					provider.dependencies.each do |dependency|
						dep_name = dependency.name.to_s
						dep_id = sanitize_id(dep_name)
						
						nodes[dep_name] ||= dep_id
						
						# Create edge from provider to dependency
						if dependency.private?
							lines << "    #{node_id}[#{name}] -.-> #{dep_id}[#{dep_name}]"
						else
							lines << "    #{node_id}[#{name}] --> #{dep_id}[#{dep_name}]"
						end
					end
					
					# A provision provides other provisions...
					provider.provisions.each do |provision_name, provision|
						next if name == provision_name.to_s
						
						provision_str = provision_name.to_s
						provision_id = sanitize_id(provision_str)
						
						nodes[provision_str] ||= provision_id
						
						# Mark this node as a provider
						providers.add(name)
						
						# Create edge from provision to provider (undirected)
						lines << "    #{provision_id}[#{provision_str}] --- #{node_id}[#{name}]"
					end
				end
				
				# Add styling
				lines << ""
				lines << "    %% Styles"
				
				# Style providers with light blue
				providers.each do |name|
					lines << "    style #{sanitize_id(name)} fill:#add8e6"
				end
				
				# Highlight provisions in the chain with a thicker border
				provisions_in_chain.each do |name|
					if node_id = nodes[name]
						lines << "    style #{node_id} stroke-width:3px"
					end
				end
				
				return lines.join("\n")
			end
		end
	end
end
