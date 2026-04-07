# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2026, by Samuel Williams.

require "build/dependency_context"

describe Build::Dependency do
	with "test packages" do
		let(:a) do
			Build::DependencyContext::Package.new("Library/Frobulate").tap do |package|
				package.provides "Test/Frobulate" do
				end
			end
		end
		
		let(:b) do
			Build::DependencyContext::Package.new("Library/Barbulate").tap do |package|
				package.provides "Test/Barbulate" do
				end
			end
		end
		
		it "should resolve all tests" do
			chain = Build::Dependency::Chain.expand(["Test/*"], [a, b])
			expect(chain.ordered.collect(&:provider)).to be == [a, b]
			expect(chain.unresolved).to be == []
		end
		
		it "should match non-wildcard dependencies" do
			# Test that non-wildcard matching works
			dependency = Build::Dependency::Depends.new("Test/Frobulate")
			expect(dependency).not.to be(:wildcard?)
			expect(dependency).to be(:match?, "Test/Frobulate")
			expect(dependency).not.to be(:match?, "Test/Barbulate")
		end
	end
end
