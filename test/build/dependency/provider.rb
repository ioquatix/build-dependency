# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2017-2025, by Samuel Williams.

require "build/dependency_context"

describe Build::Dependency::Provider do
	include Build::DependencyContext::AppPackages
	
	let(:provider) do
		Build::DependencyContext::Package.new("test").tap do |package|
			package.depends "a", private: true
			package.depends "b", public: true
			package.depends :variant
			
			package.provides "c" do
				puts "Hello World"
			end
			
			package.provides platform: "linux"
		end
	end
	
	it "should have specified dependencies" do
		expect(provider.dependencies.count).to be == 3
	end
	
	it "should have specified provisions" do
		expect(provider.provisions.count).to be == 2
	end
	
	with Build::Dependency::Provision do
		let(:subject) {provider.provisions["c"]}
		
		it "should have name" do
			expect(subject.name).to be == "c"
		end
		
		it "should not be an alias" do
			expect(subject).not.to be(:alias?)
		end
		
		it "should format nicely" do
			expect(subject.to_s).to be == 'provides "c"'
		end
	end
	
	with "Build::Dependency::Depends (private)" do
		let(:subject) {provider.dependencies["a"]}
		
		it "should have a name" do
			expect(subject.name).to be == "a"
		end
		
		it "should not be an alias" do
			expect(subject).not.to be(:alias?)
		end
		
		it "should format nicely" do
			expect(subject.to_s).to be == "depends on \"a\" #{{private: true}.inspect}"
		end
		
		it "should be private" do
			expect(subject).to be(:private?)
		end
		
		it "should not be public" do
			expect(subject).not.to be(:public?)
		end
	end
	
	with "Build::Dependency::Depends (public)" do
		let(:subject) {provider.dependencies["b"]}
		
		it "should be public" do
			expect(subject).to be(:public?)
		end
		
		it "should not be private" do
			expect(subject).not.to be(:private?)
		end
	end
	
	with "Build::Dependency::Depends (variant)" do
		let(:subject) {provider.dependencies[:variant]}
		
		it "should not be public" do
			expect(subject).not.to be(:public?)
		end
		
		it "should not be private" do
			expect(subject).not.to be(:private?)
		end
	end
	
	with Build::Dependency::Alias do
		let(:subject) {provider.provisions[:platform]}
		
		it "should be an alias" do
			expect(subject).to be(:alias?)
		end
		
		it "should format nicely" do
			expect(subject.to_s).to be == 'provides :platform -> "linux"'
		end
		
		it "should enumerate dependencies" do
			# Create a package with an alias that has dependencies
			pkg = Build::DependencyContext::Package.new("multi-platform")
			pkg.provides :os => ["linux", "darwin"]
			
			alias_provision = pkg.provisions[:os]
			expect(alias_provision).to be(:alias?)
			
			# Check the raw dependencies array first
			expect(alias_provision.dependencies).to be == ["linux", "darwin"]
			
			# Enumerate with a block
			dependencies = []
			alias_provision.each_dependency do |dep|
				dependencies << dep
			end
			
			expect(dependencies.size).to be == 2
			expect(dependencies[0]).to be_a(Build::Dependency::Depends)
			expect(dependencies[0].name).to be == "linux"
			expect(dependencies[1]).to be_a(Build::Dependency::Depends)
			expect(dependencies[1].name).to be == "darwin"
		end
	end
	
	it "should check dependencies" do
		a_dep = Build::Dependency::Depends.new("a")
		b_dep = Build::Dependency::Depends.new("b")
		missing_dep = Build::Dependency::Depends.new("does-not-exist")
		
		expect(provider.dependencies).to be(:include?, a_dep)
		expect(provider.dependencies).to be(:include?, b_dep)
		expect(provider.dependencies).not.to be(:include?, missing_dep)
	end
	
	with Build::Dependency::Provision do
		let(:provision) {provider.provisions["c"]}
		
		it "should enumerate provider dependencies" do
			# Each provision can enumerate its provider's dependencies
			dependencies = []
			provision.each_dependency do |dep|
				dependencies << dep
			end
			
			expect(dependencies.size).to be == 3
			expect(dependencies).to be(:include?, Build::Dependency::Depends.new("a", private: true))
		end
	end
	
	with Build::Dependency::Resolution do
		let(:simple_provider) do
			Build::DependencyContext::Package.new("simple").tap do |package|
				package.provides "simple"
			end
		end
		
		let(:chain) {Build::Dependency::Chain.expand(["simple"], [simple_provider])}
		let(:resolution) {chain.ordered.first}
		
		it "should have name from dependency" do
			expect(resolution.name).to be == "simple"
		end
	end
	
	with "Depends without options" do
		let(:simple_dep) {Build::Dependency::Depends.new("simple")}
		
		it "should format without options" do
			expect(simple_dep.to_s).to be == 'depends on "simple"'
		end
	end
	
	it "can freeze a provider" do
		pkg = Build::DependencyContext::Package.new("frozen")
		pkg.provides "frozen"
		pkg.depends "something"
		
		expect(pkg.freeze).to be == pkg
		expect(pkg).to be(:frozen?)
	end
end
