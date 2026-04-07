# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "build/dependency_context"

describe Build::Dependency::Visualization do
	include Build::DependencyContext::AppPackages
	
	let(:subject) {Build::Dependency::Visualization.new}
	
	it "should visualize dependency chain" do
		chain = Build::Dependency::Chain.expand(["app", "tests"], packages)
		
		mermaid = subject.generate(chain)
		
		expect(mermaid).to be_a(String)
		expect(mermaid).to be(:include?, "flowchart")
	end
end
