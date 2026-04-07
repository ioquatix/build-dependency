# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "build/dependency_context"

describe Build::Dependency::PartialChain do
	with "app chain" do
		include Build::DependencyContext::AppPackages
		
		let(:chain) {Build::Dependency::Chain.expand(["app", "lib"], packages)}
		
		it "should generate full list of ordered providers" do
			expect(chain.ordered).to be == [
				variant.resolution_for(Build::Dependency::Depends.new("Variant/debug")),
				platform.resolution_for(Build::Dependency::Depends.new("Platform/linux")),
				compiler.resolution_for(Build::Dependency::Depends.new("Language/C++17", private: true)),
				lib.resolution_for(Build::Dependency::Depends.new("lib", private: true)),
				app.resolution_for(Build::Dependency::Depends.new("app")),
			]
		end
		
		it "should generate a full list of provisions" do
			expect(chain.provisions).to be == [
				variant.provision_for(Build::Dependency::Depends.new("Variant/debug")),
				platform.provision_for(Build::Dependency::Depends.new("Platform/linux")),
				compiler.provision_for(Build::Dependency::Depends.new("Language/C++17", private: true)),
				lib.provision_for(Build::Dependency::Depends.new("lib", private: true)),
				compiler.provision_for(Build::Dependency::Depends.new("Language/C++14", private: true)),
				app.provision_for(Build::Dependency::Depends.new("app")),
				lib.provision_for(Build::Dependency::Depends.new("lib")),
			]
			
			# Generate mermaid diagram
			expect(visualization.generate(chain)).to be_a(String)
		end
		
		let(:subject) {Build::Dependency::PartialChain.new(chain, app.dependencies)}
		
		it "should select app packages" do
			expect(subject.ordered).to be == [
				variant.resolution_for(Build::Dependency::Depends.new("Variant/debug")),
				platform.resolution_for(Build::Dependency::Depends.new("Platform/linux")),
				lib.resolution_for(Build::Dependency::Depends.new("lib", private: true)),
				compiler.resolution_for(Build::Dependency::Depends.new("Language/C++14", private: true)),
			]
			
			# Generate mermaid diagram
			expect(visualization.generate(subject)).to be_a(String)
		end
	end
	
	with "private dependencies" do
		let(:a) do
			Build::DependencyContext::Package.new("a").tap do |package|
				package.provides "a"
			end
		end
		
		let(:b) do
			Build::DependencyContext::Package.new("b").tap do |package|
				package.provides "b"
				package.depends "a", private: true
			end
		end
		
		let(:c) do
			Build::DependencyContext::Package.new("c").tap do |package|
				package.provides "c"
				package.depends "b"
			end
		end
		
		let(:d) do
			Build::DependencyContext::Package.new("d").tap do |package|
				package.provides "d"
				package.depends "c"
			end
		end
		
		let(:chain) {Build::Dependency::Chain.expand(["d"], [a, b, c, d])}
		
		it "should include direct private dependencies" do
			partial_chain = chain.partial(b)
			
			expect(partial_chain.ordered.collect(&:provider)).to be == [a]
		end
		
		it "shouldn't include nested private dependencies" do
			partial_chain = chain.partial(c)
			
			expect(partial_chain.ordered.collect(&:provider)).to be == [b]
		end
		
		it "should follow non-private dependencies" do
			partial_chain = chain.partial(d)
			
			expect(partial_chain.ordered.collect(&:provider)).to be == [b, c]
		end
		
		it "should access underlying chain selection" do
			partial_chain = chain.partial(d)
			
			expect(partial_chain.selection).to be == chain.selection
		end
		
		it "should access underlying chain providers" do
			partial_chain = chain.partial(d)
			
			expect(partial_chain.providers).to be == chain.providers
		end
		
		it "can freeze a partial chain" do
			partial_chain = chain.partial(d)
			
			expect(partial_chain.freeze).to be == partial_chain
			expect(partial_chain).to be(:frozen?)
		end
	end
end
