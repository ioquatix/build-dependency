# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

module Build
	module Dependency
		# Generates Mermaid flowchart visualizations of dependency chains.
		class Visualization
			# Convert a name to a valid Mermaid node ID.
			# @parameter name [String] The name to sanitize.
			# @returns [String] A sanitized identifier safe for use in Mermaid diagrams.
			def sanitize_id(name)
				# Convert name to a valid Mermaid node ID
				name.to_s.gsub(/[^a-zA-Z0-9_]/, "_")
			end
			
			# Generate a Mermaid flowchart diagram for a dependency chain.
			# @parameter chain [Chain] The dependency chain to visualize.
			# @returns [String] A Mermaid flowchart diagram in text format.
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
