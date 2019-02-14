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

require_relative 'package'

RSpec.describe Build::Dependency do
	describe "valid dependency resolution" do
		let(:a) do
			Package.new('apple-tree').tap do |package|
				package.provides 'apple' do
					fruit ['apple']
				end
			end
		end
		
		let(:b) do
			Package.new('orange-tree').tap do |package|
				package.provides 'orange' do
					fruit ['orange']
				end
			end
		end
		
		let(:c) do
			Package.new('blender').tap do |package|
				package.provides 'fruit-juice' do
					juice ['ice', 'cold']
				end
				
				package.depends 'apple'
				package.depends 'orange'
			end
		end
		
		it "should resolve direct dependency chain" do
			chain = Build::Dependency::Chain.expand(['fruit-juice'], [a, b, c])
			expect(chain.ordered.collect(&:provider)).to be == [a, b, c]
			expect(chain.unresolved).to be == []
		end
		
		it "should resolve wildcard dependency chain" do
			chain = Build::Dependency::Chain.expand(['fruit-*'], [a, b, c])
			expect(chain.ordered.collect(&:provider)).to be == [a, b, c]
			expect(chain.unresolved).to be == []
		end
		
		let(:d) do
			Package.new('bakery').tap do |package|
				package.provides 'pie'
				package.depends 'apple'
			end
		end
		
		it "shouldn't include unrelated units" do
			chain = Build::Dependency::Chain.expand(['pie'], [a, b, c, d])
			
			expect(chain.unresolved).to be == []
			expect(chain.ordered.collect(&:provider)).to be == [a, d]
		end
		
		it "should format nicely" do
			chain = Build::Dependency::Chain.expand(['fruit-juice'], [a, b, c])
			resolution = chain.ordered.first
			expect(resolution.to_s).to be == 'resolution "apple-tree" -> "apple"'
		end
	end
	
	describe "incomplete dependency resolution" do
		it "should report conflicts" do
			apple = Package.new('apple')
			apple.provides 'apple'
			apple.provides 'fruit'
		
			bananna = Package.new('bananna')
			bananna.provides 'fruit'
		
			salad = Package.new('salad')
			salad.depends 'fruit'
			salad.provides 'salad'
		
			chain = Build::Dependency::Chain.new(['salad'], [apple, bananna, salad])
			expect(chain.unresolved.first).to be == [Build::Dependency::Depends.new("fruit"), salad]
			expect(chain.conflicts).to be == {Build::Dependency::Depends.new("fruit") => [apple, bananna]}
		
			chain = Build::Dependency::Chain.new(['salad'], [apple, bananna, salad], ['apple'])
			expect(chain.unresolved).to be == []
			expect(chain.conflicts).to be == {}
		end
	end
	
	describe "multiple provisions" do
		let(:fruit) do
			Package.new('fruit').tap do |package|
				package.provides 'apple' do
				end
				
				package.provides 'orange' do
				end
			end
		end
		
		let(:salad) do
			Package.new('salad').tap do |package|
				package.depends 'apple'
				package.depends 'orange'
				package.provides 'salad'
			end
		end
		
		let(:lunch) do
			Package.new('lunch').tap do |package|
				package.depends 'apple'
				package.depends 'salad'
				package.provides 'lunch'
			end
		end
		
		let(:chain) {Build::Dependency::Chain.new(['lunch'], [fruit, salad, lunch])}
		
		it "should include both provisions" do
			expect(chain.provisions.count).to be == 4
			expect(chain.provisions.collect(&:name)).to be == ['apple', 'orange', 'salad', 'lunch']
		end
		
		it "should include both provisions in partial chain" do
			partial_chain = chain.partial(lunch)
			expect(partial_chain.provisions.count).to be == 3
			expect(partial_chain.provisions.collect(&:name)).to be == ['apple', 'orange', 'salad']
		end
	end
	
	it "should resolve aliases" do
		apple = Package.new('apple')
		apple.provides 'apple'
		apple.provides :fruit => 'apple'
	
		bananna = Package.new('bananna')
		bananna.provides 'bananna'
		bananna.provides :fruit => 'bananna'
	
		salad = Package.new('salad')
		salad.depends :fruit
		salad.provides 'salad'
	
		chain = Build::Dependency::Chain.expand(['salad'], [apple, bananna, salad], ['apple'])
		expect(chain.unresolved).to be == []
		expect(chain.conflicts).to be == {}
		
		expect(chain.ordered.size).to be == 2
		expect(chain.ordered[0].provider).to be == apple
		expect(chain.ordered[1].provider).to be == salad
	end
	
	it "should select dependencies with high priority" do
		bad_apple = Package.new('bad_apple')
		bad_apple.provides 'apple'
		bad_apple.priority = 20
		
		good_apple = Package.new('good_apple')
		good_apple.provides 'apple'
		good_apple.priority = 40
		
		chain = Build::Dependency::Chain.expand(['apple'], [bad_apple, good_apple])
		
		expect(chain.unresolved).to be == []
		expect(chain.conflicts).to be == {}
		
		# Should select higher priority package by default:
		expect(chain.ordered).to be == [good_apple.resolution_for(
			Build::Dependency::Depends['apple']
		)]
	end
	
	it "should expose direct dependencies" do
		system = Package.new('linux')
		system.provides 'linux'
		system.provides 'clang'
		system.provides system: 'linux'
		system.provides compiler: 'clang'
		
		library = Package.new('library')
		library.provides 'library'
		library.depends :system
		library.depends :compiler
		
		application = Package.new('application')
		application.provides 'application'
		application.depends :compiler
		application.depends 'library'
		
		chain = Build::Dependency::Chain.expand(['application'], [system, library, application])
		
		expect(chain.unresolved).to be == []
		expect(chain.conflicts).to be == {}
		expect(chain.ordered).to be == [
			system.resolution_for(Build::Dependency::Depends.new('clang')),
			library.resolution_for(Build::Dependency::Depends.new('library')),
			application.resolution_for(Build::Dependency::Depends.new('application')),
		]
	end
end
