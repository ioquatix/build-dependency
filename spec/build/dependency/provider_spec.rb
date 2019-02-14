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

RSpec.describe Build::Dependency::Provider do
	include_context "app packages"
	
	let(:provider) do
		Package.new("test").tap do |package|
			package.depends "a", private: true
			package.depends "b"
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
	
	describe Build::Dependency::Provision do
		subject {provider.provisions["c"]}
		
		it "should have name" do
			expect(subject.name).to be == "c"
		end
		
		it "should not be an alias" do
			is_expected.to_not be_alias
		end
		
		it "should format nicely" do
			expect(subject.to_s).to be == 'provides "c"'
		end
	end
	
	describe Build::Dependency::Depends do
		subject {provider.dependencies.first}
		
		it "should have a name" do
			expect(subject.name).to be == "a"
		end
		
		it "should not be an alias" do
			is_expected.to_not be_alias
		end
		
		it "should format nicely" do
			expect(subject.to_s).to be == 'depends on "a" {:private=>true}'
		end
	end
	
	describe Build::Dependency::Alias do
		subject {provider.provisions[:platform]}
		
		it "should be an alias" do
			is_expected.to be_alias
		end
		
		it "should format nicely" do
			expect(subject.to_s).to be == 'provides :platform -> "linux"'
		end
	end
end
